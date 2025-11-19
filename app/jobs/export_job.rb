class ExportJob < ApplicationJob
  queue_as :default

  def perform(execution_id)
    execution = MigrationExecution.find(execution_id)
    migration_plan = execution.migration_plan

    Exports::GeneratorService.new(migration_plan, execution).call
  rescue StandardError => e
    Rails.logger.error("ExportJob failed for execution #{execution_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Only update if the service didn't already mark it as failed
    if execution.reload.status != 'failed'
      execution.update!(
        status: :failed,
        completed_at: Time.current,
        error_log: e.full_message
      )
    end

    # Don't re-raise - allow the job to complete so Sidekiq doesn't retry
    # The error is already logged and saved to the execution record
  end
end
