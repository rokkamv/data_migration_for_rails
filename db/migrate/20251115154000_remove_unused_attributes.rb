# frozen_string_literal: true

class RemoveUnusedAttributes < ActiveRecord::Migration[7.0]
  def change
    # Remove unused columns from migration_plans
    remove_column :migration_plans, :settings, :text if column_exists?(:migration_plans, :settings)

    # Remove unused columns from migration_steps
    remove_column :migration_steps, :model_filters, :text if column_exists?(:migration_steps, :model_filters)
    remove_column :migration_steps, :association_selections, :text if column_exists?(:migration_steps,
                                                                                     :association_selections)
    remove_column :migration_steps, :polymorphic_associations, :text if column_exists?(:migration_steps,
                                                                                       :polymorphic_associations)
    remove_column :migration_steps, :included_models, :text if column_exists?(:migration_steps, :included_models)
    remove_column :migration_steps, :excluded_models, :text if column_exists?(:migration_steps, :excluded_models)
  end
end
