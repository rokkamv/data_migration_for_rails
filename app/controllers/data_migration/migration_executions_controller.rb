# frozen_string_literal: true

module DataMigration
  class MigrationExecutionsController < ApplicationController
    include DataMigration::PunditAuthorization

    before_action :set_execution, only: %i[show download]

    def index
      @executions = policy_scope(MigrationExecution).recent.includes(:migration_plan, :user)
    end

    def show
      authorize @execution

      # Initialize variables
      @migration_records = []
      @model_names = []
      @action_counts = {}

      # Only load migration records for import executions
      return unless @execution.import_type?

      # Reload association to ensure fresh data
      @execution.reload

      # Filter and paginate migration records
      @migration_records = @execution.migration_records.order(created_at: :desc)

      # Apply filters if provided
      @migration_records = @migration_records.by_model(params[:model]) if params[:model].present?

      @migration_records = @migration_records.by_action(params[:filter_action]) if params[:filter_action].present?

      # Limit to 500 records for display (can be customized)
      @limit = (params[:limit] || 500).to_i
      @migration_records = @migration_records.limit(@limit).to_a

      # Get unique model names for filter dropdown
      @model_names = @execution.migration_records.distinct.pluck(:migrated_model_name).sort

      # Get total counts by action (convert enum integers to string keys)
      raw_counts = @execution.migration_records.group(:action).count
      raw_counts.each do |action_value, count|
        action_name = MigrationRecord.actions.key(action_value)
        @action_counts[action_name] = count if action_name
      end
    end

    def download
      authorize @execution, :download?

      unless @execution.completed? && @execution.export_type? && @execution.file_path.present?
        redirect_to @execution, alert: 'Export file not available.'
        return
      end

      unless File.exist?(@execution.file_path)
        redirect_to @execution, alert: 'Export file not found.'
        return
      end

      send_file @execution.file_path,
                filename: File.basename(@execution.file_path),
                type: 'application/gzip',
                disposition: 'attachment'
    end

    private

    def set_execution
      @execution = MigrationExecution.find(params[:id])
    end
  end
end
