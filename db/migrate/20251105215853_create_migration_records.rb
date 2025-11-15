class CreateMigrationRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :migration_records do |t|
      t.references :migration_execution, null: false, foreign_key: true
      t.string :migrated_model_name
      t.string :record_identifier
      t.integer :action
      t.text :record_changes
      t.text :error_message

      t.timestamps
    end
  end
end
