module DataMigration
  class ImportsController < ApplicationController
    before_action :set_migration_plan

    def new
      authorize @migration_plan, :execute?
    end

    def create
      authorize @migration_plan, :execute?

      unless params[:archive_file].present?
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}/import/new", alert: 'Please select a file to upload.'
        return
      end

      uploaded_file = params[:archive_file]

      # Save uploaded file to tmp directory
      file_path = save_uploaded_file(uploaded_file)

      execution = MigrationExecution.create!(
        migration_plan: @migration_plan,
        user: current_user,
        execution_type: :import,
        status: :pending,
        file_path: file_path
      )

      ImportJob.perform_later(execution.id)

      redirect_to "/data_migration/migration_executions/#{execution.id}", notice: 'Import started. You will be notified when it completes.'
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:migration_plan_id])
    end

    def save_uploaded_file(uploaded_file)
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      filename = "import_#{timestamp}_#{uploaded_file.original_filename}"
      file_path = Rails.root.join('tmp', 'imports', filename)

      FileUtils.mkdir_p(File.dirname(file_path))

      File.open(file_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end

      file_path.to_s
    end
  end
end
