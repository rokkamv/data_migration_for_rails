# frozen_string_literal: true

class AddUserForeignKeys < ActiveRecord::Migration[7.0]
  def change
    # Add user_id to migration_plans if not exists
    unless column_exists?(:migration_plans, :user_id)
      add_reference :migration_plans, :user, null: false, foreign_key: { to_table: :data_migration_users }
    end

    # Add user_id to migration_executions if not exists
    return if column_exists?(:migration_executions, :user_id)

    add_reference :migration_executions, :user, null: false, foreign_key: { to_table: :data_migration_users }
  end
end
