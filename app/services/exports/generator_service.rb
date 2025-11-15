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

      csv_path = File.join(temp_dir, "#{step.source_model_name}_export.csv")

      CSV.open(csv_path, "wb") do |csv|
        csv << headers_for_step(step, model_class)

        records.find_each do |record|
          csv << row_data_for_record(record, step)
          @stats[:processed_records] += 1
          update_progress if @stats[:processed_records] % 100 == 0
        end
      end
    rescue StandardError => e
      @stats[:errors] << { step: step.source_model_name, error: e.message }
      raise
    end

    def get_records_for_step(step, model_class)
      if step.filter_query.present?
        # Safely evaluate the filter query
        model_class.instance_eval(step.filter_query)
      else
        model_class.all
      end
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
  end
end
