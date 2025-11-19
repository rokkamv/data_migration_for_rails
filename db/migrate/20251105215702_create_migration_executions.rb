class CreateMigrationExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :migration_executions do |t|
      t.references :migration_plan, null: false, foreign_key: true
      # user_id will be added by AddUserForeignKeys migration
      t.integer :execution_type, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.string :file_path
      t.text :stats
      t.text :error_log

      t.timestamps
    end

    add_index :migration_executions, :status
    add_index :migration_executions, :execution_type
    add_index :migration_executions, :started_at
  end
end
