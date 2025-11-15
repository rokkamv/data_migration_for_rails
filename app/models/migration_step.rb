class MigrationStep < ApplicationRecord
  # Serialization
  serialize :dependee_attribute_mapping, coder: JSON
  serialize :column_overrides, coder: JSON
  serialize :association_overrides, coder: JSON
  serialize :included_models, Array, coder: JSON
  serialize :excluded_models, Array, coder: JSON
  serialize :model_filters, coder: JSON
  serialize :association_selections, coder: JSON
  serialize :polymorphic_associations, coder: JSON

  # Associations
  belongs_to :migration_plan
  belongs_to :dependee, class_name: 'MigrationStep', optional: true
  has_many :dependents, class_name: 'MigrationStep', foreign_key: :dependee_id

  # Validations
  validates :source_model_name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true }

  # Callbacks to set defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :ordered_by_sequence, -> { order(:sequence) }

  private

  def set_defaults
    self.dependee_attribute_mapping ||= {}
    self.column_overrides ||= {}
    self.association_overrides ||= {}
    self.included_models ||= []
    self.excluded_models ||= []
    self.model_filters ||= {}
    self.association_selections ||= {}
    self.polymorphic_associations ||= {}
  end
end
