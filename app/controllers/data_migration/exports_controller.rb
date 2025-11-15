module DataMigration
  class ExportsController < ApplicationController
    before_action :set_migration_plan

    def create
      authorize @migration_plan, :execute?

      execution = MigrationExecution.create!(
        migration_plan: @migration_plan,
        user: current_user,
        execution_type: :export,
        status: :pending
      )

      ExportJob.perform_later(execution.id)

      redirect_to "/data_migration/migration_executions/#{execution.id}", notice: 'Export started. You will be notified when it completes.'
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:migration_plan_id])
    end
  end
end
