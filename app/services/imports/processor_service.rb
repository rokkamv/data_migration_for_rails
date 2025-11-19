require 'csv'
require 'fileutils'
require 'zlib'
require 'rubygems/package'

module Imports
  class ProcessorService
    attr_reader :migration_plan, :execution, :uploaded_file

    def initialize(migration_plan, execution, uploaded_file_path)
      @migration_plan = migration_plan
      @execution = execution
      @uploaded_file_path = uploaded_file_path
      @stats = {
        total_steps: migration_plan.migration_steps.count,
        completed_steps: 0,
        total_records: 0,
        processed_records: 0,
        created: 0,
        updated: 0,
        skipped: 0,
        failed: 0,
        errors: []
      }
      @id_mapping = {} # Maps old IDs to new IDs for foreign key updates
    end

    def call
      execution.update!(status: :running, started_at: Time.current)

      Dir.mktmpdir do |temp_dir|
        begin
          extract_archive(temp_dir)
          import_all_steps(temp_dir)
          finalize_success
        rescue StandardError => e
          finalize_failure(e)
        end
      end
    end

    private

    def extract_archive(temp_dir)
      Gem::Package::TarReader.new(Zlib::GzipReader.open(@uploaded_file_path)) do |tar|
        tar.each do |entry|
          next unless entry.file?

          file_path = File.join(temp_dir, entry.full_name)
          FileUtils.mkdir_p(File.dirname(file_path))

          File.open(file_path, 'wb') do |f|
            f.write(entry.read)
          end
        end
      end
    end

    def import_all_steps(temp_dir)
      migration_plan.migration_steps.order(:sequence).each do |step|
        import_step(step, temp_dir)
        @stats[:completed_steps] += 1
        update_progress
      end
    end

    def import_step(step, temp_dir)
      csv_path = File.join(temp_dir, "#{step.source_model_name}_export.csv")
      return unless File.exist?(csv_path)

      model_class = step.source_model_name.constantize
      rows = CSV.read(csv_path, headers: true)

      @stats[:total_records] += rows.count
      update_progress

      rows.each do |row|
        process_row(row, step, model_class)
        @stats[:processed_records] += 1
        update_progress if @stats[:processed_records] % 50 == 0
      end
    rescue StandardError => e
      @stats[:errors] << { step: step.source_model_name, error: e.message }
      raise
    end

    def process_row(row, step, model_class)
      # Build attributes hash from CSV row
      attributes = build_attributes(row, step, model_class)

      # Update foreign key associations (pass CSV row for association attribute values)
      update_foreign_keys(attributes, step, row)

      # Find or create record
      existing_record = find_existing_record(attributes, step, model_class)

      if existing_record
        handle_existing_record(existing_record, attributes, step, row)
      else
        handle_new_record(attributes, step, model_class, row)
      end
    rescue StandardError => e
      @stats[:failed] += 1
      record_migration_action(step, row, :failed, {}, e.message)
    end

    def build_attributes(row, step, model_class)
      attributes = {}

      model_class.column_names.each do |column|
        attributes[column] = row[column] if row.key?(column)
      end

      attributes
    end

    def update_foreign_keys(attributes, step, csv_row)
      return unless step.association_overrides.present?

      step.association_overrides.each do |fk_column, mapping_info|
        next unless attributes[fk_column].present?

        # Check if this is a polymorphic association
        if mapping_info['polymorphic'] == true
          handle_polymorphic_foreign_key(attributes, fk_column, mapping_info, csv_row)
        else
          handle_regular_foreign_key(attributes, fk_column, mapping_info, csv_row)
        end
      end
    end

    def handle_regular_foreign_key(attributes, fk_column, mapping_info, csv_row)
      old_id = attributes[fk_column].to_i
      target_model = mapping_info['model']
      lookup_attributes = mapping_info['lookup_attributes']

      # Find the new ID based on lookup attributes
      new_id = find_mapped_id(old_id, target_model, lookup_attributes, csv_row)
      attributes[fk_column] = new_id if new_id
    end

    def handle_polymorphic_foreign_key(attributes, fk_column, mapping_info, csv_row)
      type_column = mapping_info['type_column']

      # Get the polymorphic type from the attributes
      polymorphic_type = attributes[type_column]
      return unless polymorphic_type.present?

      # Get the lookup attributes for this specific type
      lookup_attributes_by_type = mapping_info['lookup_attributes']
      return unless lookup_attributes_by_type.is_a?(Hash)

      lookup_attributes = lookup_attributes_by_type[polymorphic_type]
      return unless lookup_attributes.present?

      # Find the new ID based on the polymorphic type and lookup attributes
      old_id = attributes[fk_column].to_i
      new_id = find_mapped_id(old_id, polymorphic_type, lookup_attributes, csv_row)
      attributes[fk_column] = new_id if new_id
    end

    def find_mapped_id(old_id, target_model, lookup_attributes, csv_row)
      # Check if we've already mapped this ID (cache for performance)
      mapping_key = "#{target_model}_#{old_id}"
      return @id_mapping[mapping_key] if @id_mapping.key?(mapping_key)

      # Build conditions hash from CSV row using lookup attributes
      # For association_overrides, the association name would be something like 'company'
      # and CSV columns would be like 'company.name', 'company.code'
      conditions = {}

      # Determine association name from the target model
      # e.g., "Company" -> "company", "Project" -> "project"
      association_name = target_model.underscore

      Array(lookup_attributes).each do |attr|
        # Look for CSV column like "company.name"
        csv_column = "#{association_name}.#{attr}"
        if csv_row.key?(csv_column) && csv_row[csv_column].present?
          conditions[attr] = csv_row[csv_column]
        end
      end

      # If we have conditions, query the database
      if conditions.present?
        begin
          model_class = target_model.constantize
          found_record = model_class.find_by(conditions)

          if found_record
            # Cache this mapping for future lookups
            @id_mapping[mapping_key] = found_record.id
            return found_record.id
          else
            Rails.logger.warn "Could not find #{target_model} with #{conditions.inspect} for old_id #{old_id}"
          end
        rescue NameError => e
          Rails.logger.error "Model #{target_model} not found: #{e.message}"
        end
      end

      # Fallback: return old_id (might work if IDs are the same in both DBs)
      old_id
    end

    def find_existing_record(attributes, step, model_class)
      return nil if step.column_overrides.blank? || step.column_overrides['uniq_record_id_cols'].blank?

      unique_columns = Array(step.column_overrides['uniq_record_id_cols'])
      conditions = {}

      unique_columns.each do |column|
        conditions[column] = attributes[column]
      end

      model_class.find_by(conditions)
    end

    def handle_existing_record(record, attributes, step, csv_row)
      # Check if source record is newer
      if should_update?(record, attributes)
        # Remove columns that should be ignored on update
        ignored_columns = step.column_overrides&.dig('ignore_on_update') || []
        update_attrs = attributes.except(*ignored_columns, 'id', 'created_at')

        changes = record.attributes.slice(*update_attrs.keys).to_h.select { |k, v| v != update_attrs[k] }

        if record.update(update_attrs)
          @stats[:updated] += 1
          record_migration_action(step, csv_row, :updated, changes)
        else
          @stats[:failed] += 1
          record_migration_action(step, csv_row, :failed, {}, record.errors.full_messages.join(', '))
        end
      else
        @stats[:skipped] += 1
        record_migration_action(step, csv_row, :skipped, {})
      end

      # Store ID mapping
      if csv_row['id'].present?
        mapping_key = "#{step.source_model_name}_#{csv_row['id']}"
        @id_mapping[mapping_key] = record.id
      end
    end

    def handle_new_record(attributes, step, model_class, csv_row)
      # Remove id from attributes to let database assign new one
      old_id = attributes.delete('id')
      attributes.delete('created_at')
      attributes.delete('updated_at')

      record = model_class.new(attributes)

      if record.save
        @stats[:created] += 1
        record_migration_action(step, csv_row, :created, attributes)

        # Store ID mapping
        if old_id.present?
          mapping_key = "#{step.source_model_name}_#{old_id}"
          @id_mapping[mapping_key] = record.id
        end
      else
        @stats[:failed] += 1
        record_migration_action(step, csv_row, :failed, {}, record.errors.full_messages.join(', '))
      end
    end

    def should_update?(record, attributes)
      # If no updated_at in import data, always update
      return true unless attributes['updated_at'].present?

      source_updated_at = Time.zone.parse(attributes['updated_at'].to_s) rescue nil
      return true unless source_updated_at

      # Update if source is newer
      source_updated_at > record.updated_at
    end

    def record_migration_action(step, csv_row, action, changes, error_message = nil)
      record_identifier = csv_row['id'].present? ? "#{step.source_model_name}##{csv_row['id']}" : "unknown"

      MigrationRecord.create!(
        migration_execution: execution,
        migrated_model_name: step.source_model_name,
        record_identifier: record_identifier,
        action: action,
        record_changes: changes,
        error_message: error_message
      )
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
      "#{@stats[:processed_records]}/#{@stats[:total_records]} records imported " \
      "(#{@stats[:created]} created, #{@stats[:updated]} updated, #{@stats[:skipped]} skipped, #{@stats[:failed]} failed)"
    end

    def finalize_success
      execution.update!(
        status: :completed,
        completed_at: Time.current,
        stats: @stats
      )

      broadcast_completion('Import completed successfully')
    end

    def finalize_failure(error)
      @stats[:errors] << { general: error.message }

      execution.update!(
        status: :failed,
        completed_at: Time.current,
        error_log: error.full_message,
        stats: @stats
      )

      broadcast_completion("Import failed: #{error.message}")
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
  end
end
