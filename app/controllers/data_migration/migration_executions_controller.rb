module DataMigration
  class MigrationExecutionsController < ApplicationController
    before_action :set_execution, only: [:show, :download]

    def index
      @executions = policy_scope(MigrationExecution).recent.includes(:migration_plan, :user)
    end

    def show
      authorize @execution
      @migration_records = @execution.migration_records.order(created_at: :desc).limit(100)
    end

    def download
      authorize @execution, :download?

      unless @execution.completed? && @execution.export? && @execution.file_path.present?
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
