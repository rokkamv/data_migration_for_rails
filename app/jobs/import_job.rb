class ImportJob < ApplicationJob
  queue_as :default

  def perform(execution_id)
    execution = MigrationExecution.find(execution_id)
    migration_plan = execution.migration_plan
    uploaded_file_path = execution.file_path

    Imports::ProcessorService.new(migration_plan, execution, uploaded_file_path).call
  rescue StandardError => e
    Rails.logger.error("ImportJob failed for execution #{execution_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    execution.update!(
      status: :failed,
      completed_at: Time.current,
      error_log: e.full_message
    )

    raise
  end
end
