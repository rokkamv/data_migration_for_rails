require 'csv'
require 'fileutils'
require 'zlib'
require 'rubygems/package'

module Exports
  class GeneratorService
    attr_reader :migration_plan, :execution

    def initialize(migration_plan, execution)
      @migration_plan = migration_plan
      @execution = execution
      @stats = {
        total_steps: migration_plan.migration_steps.count,
        completed_steps: 0,
        total_records: 0,
        processed_records: 0,
        errors: []
      }
      @exported_ids_cache = {} # Cache format: { step_id => { 'column_name' => [values] } }
    end

    def call
      execution.update!(status: :running, started_at: Time.current)

      Dir.mktmpdir do |temp_dir|
        begin
          export_all_steps(temp_dir)
          archive_path = create_archive(temp_dir)
          finalize_success(archive_path)
        rescue StandardError => e
          finalize_failure(e)
        end
      end
    end

    private

    def export_all_steps(temp_dir)
      migration_plan.migration_steps.order(:sequence).each do |step|
        export_step(step, temp_dir)
        @stats[:completed_steps] += 1
        update_progress
      end
    end

    def export_step(step, temp_dir)
      model_class = step.source_model_name.constantize
      records = get_records_for_step(step, model_class)

      @stats[:total_records] += records.count
      update_progress

      # Initialize cache for this step based on what dependent steps need
      initialize_cache_for_step(step, model_class)

      csv_path = File.join(temp_dir, "#{step.source_model_name}_export.csv")

      CSV.open(csv_path, "wb") do |csv|
        csv << headers_for_step(step, model_class)

        # Handle both ActiveRecord::Relation and Array
        if records.is_a?(Array)
          records.each do |record|
            csv << row_data_for_record(record, step)
            cache_record_values(step, record)
            @stats[:processed_records] += 1
            update_progress if @stats[:processed_records] % 100 == 0
          end
        else
          records.find_each do |record|
            csv << row_data_for_record(record, step)
            cache_record_values(step, record)
            @stats[:processed_records] += 1
            update_progress if @stats[:processed_records] % 100 == 0
          end
        end
      end
    rescue StandardError => e
      @stats[:errors] << { step: step.source_model_name, error: e.message }
      raise
    end

    def get_records_for_step(step, model_class)
      # Start with base query from filter_query or all records
      base_query = if step.filter_query.present?
        # Safely evaluate the filter query with parameter substitution
        query = step.filter_query.strip
        # Substitute placeholders with actual values
        query = substitute_filter_params(query)
        # Remove leading dot if present (e.g., '.where(...)' becomes 'where(...)')
        query = query.sub(/^\./, '')
        model_class.instance_eval(query)
      else
        model_class.all
      end

      # Apply dependee filtering if this step depends on another
      apply_dependee_filter(step, base_query, model_class)
    end

    def substitute_filter_params(query)
      result = query.dup

      # Substitute placeholders with actual values
      unless execution.filter_params.blank?
        execution.filter_params.each do |key, value|
          # Replace {{key}} with the actual value
          # Note: The placeholder should be inside quotes in the query template
          # e.g., where("created_at < ?", "{{cutoff_date}}")
          result.gsub!("{{#{key}}}", value.to_s)
        end
      end

      # Check for any remaining unsubstituted placeholders
      remaining_placeholders = result.scan(/\{\{(\w+)\}\}/).flatten
      if remaining_placeholders.any?
        raise "Filter query contains unsubstituted placeholders: #{remaining_placeholders.join(', ')}. " \
              "Please provide values for these parameters before starting the export."
      end

      result
    end

    def headers_for_step(step, model_class)
      headers = model_class.column_names.dup

      # Add association columns from column_overrides
      if step.column_overrides.present?
        step.column_overrides.each do |association, attributes|
          Array(attributes).each do |attr|
            headers << "#{association}.#{attr}"
          end
        end
      end

      headers
    end

    def row_data_for_record(record, step)
      row = []
      model_class = record.class

      # Add regular column values
      model_class.column_names.each do |column|
        row << record.send(column)
      end

      # Add association attribute values
      if step.column_overrides.present?
        step.column_overrides.each do |association, attributes|
          association_obj = record.send(association)

          Array(attributes).each do |attr|
            value = association_obj&.send(attr)
            row << value
          end
        end
      end

      row
    end

    def create_archive(temp_dir)
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      archive_name = "#{migration_plan.name.parameterize}_export_#{timestamp}.tar.gz"
      archive_path = Rails.root.join('tmp', 'exports', archive_name)

      FileUtils.mkdir_p(File.dirname(archive_path))

      Gem::Package::TarWriter.new(Zlib::GzipWriter.new(File.open(archive_path, 'wb'))) do |tar|
        Dir.glob("#{temp_dir}/*").each do |file|
          mode = File.stat(file).mode
          relative_path = File.basename(file)

          tar.add_file_simple(relative_path, mode, File.size(file)) do |tar_file|
            File.open(file, 'rb') { |f| tar_file.write(f.read) }
          end
        end
      end

      archive_path.to_s
    end

    def update_progress
      execution.update!(stats: @stats)
      broadcast_progress
    end

    def broadcast_progress
      ActionCable.server.broadcast(
        "execution_#{execution.id}",
        {
          type: 'progress',
          stats: @stats,
          percentage: calculate_percentage,
          message: progress_message
        }
      )
    end

    def calculate_percentage
      return 0 if @stats[:total_records].zero?
      ((@stats[:processed_records].to_f / @stats[:total_records].to_f) * 100).round(2)
    end

    def progress_message
      "Processing step #{@stats[:completed_steps]}/#{@stats[:total_steps]} - " \
      "#{@stats[:processed_records]}/#{@stats[:total_records]} records exported"
    end

    def finalize_success(archive_path)
      execution.update!(
        status: :completed,
        completed_at: Time.current,
        file_path: archive_path,
        stats: @stats
      )

      broadcast_completion('Export completed successfully')
    end

    def finalize_failure(error)
      @stats[:errors] << { general: error.message }

      execution.update!(
        status: :failed,
        completed_at: Time.current,
        error_log: error.full_message,
        stats: @stats
      )

      broadcast_completion("Export failed: #{error.message}")
    end

    def broadcast_completion(message)
      ActionCable.server.broadcast(
        "execution_#{execution.id}",
        {
          type: 'completion',
          status: execution.status,
          message: message,
          stats: @stats
        }
      )
    end

    # Initialize cache for a step by looking at what dependent steps need
    def initialize_cache_for_step(step, model_class)
      # Find all steps that depend on this step
      dependent_steps = migration_plan.migration_steps.where(dependee_id: step.id)

      # Determine which columns to cache
      columns_to_cache = Set.new

      dependent_steps.each do |dep_step|
        next if dep_step.dependee_attribute_mapping.blank?

        # Extract the values from dependee_attribute_mapping
        # Format: { "company_id" => "id", "manager_id" => "email" }
        dep_step.dependee_attribute_mapping.each_value do |dependee_column|
          columns_to_cache.add(dependee_column)
        end
      end

      # Initialize cache structure for this step
      if columns_to_cache.any?
        @exported_ids_cache[step.id] = {}
        columns_to_cache.each do |col|
          @exported_ids_cache[step.id][col] = []
        end
      end
    end

    # Cache specific column values from a record
    def cache_record_values(step, record)
      return unless @exported_ids_cache[step.id].present?

      @exported_ids_cache[step.id].each_key do |column_name|
        value = record.send(column_name)
        @exported_ids_cache[step.id][column_name] << value if value.present?
      end
    end

    # Apply dependee filtering to the query
    def apply_dependee_filter(step, base_query, model_class)
      # If this step has no dependee, return the base query as is
      return base_query unless step.dependee_id.present?

      # Get the dependee step
      dependee_step = migration_plan.migration_steps.find_by(id: step.dependee_id)
      return base_query unless dependee_step.present?

      # Check if dependee_attribute_mapping is configured
      return base_query if step.dependee_attribute_mapping.blank?

      # Check if we have cached values for the dependee step
      cached_values = @exported_ids_cache[dependee_step.id]
      return base_query unless cached_values.present?

      # Build where conditions based on the mapping
      # Format: { "company_id" => "id" } means filter current step's company_id
      # using the cached "id" values from dependee step
      conditions = {}

      step.dependee_attribute_mapping.each do |local_column, dependee_column|
        # Get the cached values for the dependee column
        values = cached_values[dependee_column]

        if values.present? && values.any?
          conditions[local_column] = values
        else
          Rails.logger.warn "No cached values found for #{dependee_step.source_model_name}.#{dependee_column}"
        end
      end

      # Apply the filter if we have conditions
      if conditions.present?
        base_query.where(conditions)
      else
        base_query
      end
    end
  end
end
