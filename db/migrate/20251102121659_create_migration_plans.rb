# frozen_string_literal: true

class CreateMigrationPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :migration_plans do |t|
      t.string :name, null: false
      t.text :description
      t.text :settings
      t.timestamps
    end
    add_index :migration_plans, :name, unique: true
  end
end
