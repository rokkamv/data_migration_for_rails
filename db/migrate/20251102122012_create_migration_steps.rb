class CreateMigrationSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :migration_steps do |t|
      t.references :migration_plan, null: false, foreign_key: true
      t.string :source_model_name
      t.integer :sequence
      t.string :filter_query
      t.bigint :dependee_id, index: true
      t.text :dependee_attribute_mapping
      t.text :column_overrides
      t.text :association_overrides
      t.text :included_models
      t.text :excluded_models
      t.text :model_filters
      t.text :association_selections
      t.text :polymorphic_associations
      t.timestamps
    end

    add_foreign_key :migration_steps, :migration_steps, column: :dependee_id
  end
end
