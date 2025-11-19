class AddFilterParamsToMigrationExecutions < ActiveRecord::Migration[7.0]
  def change
    add_column :migration_executions, :filter_params, :text
  end
end
