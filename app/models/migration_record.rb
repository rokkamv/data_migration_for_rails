class MigrationRecord < ApplicationRecord
  # Serialization
  serialize :record_changes, coder: JSON

  # Associations
  belongs_to :migration_execution

  # Enums
  enum action: { created: 0, updated: 1, skipped: 2, failed: 3 }

  # Validations
  validates :migrated_model_name, presence: true
  validates :record_identifier, presence: true
  validates :action, presence: true

  # Callbacks to set defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :by_action, ->(action) { where(action: action) }
  scope :by_model, ->(model_name) { where(migrated_model_name: model_name) }
  scope :errors_only, -> { where(action: :failed) }

  # Instance methods
  def display_name
    "#{migrated_model_name} #{record_identifier}"
  end

  def success?
    !failed?
  end

  private

  def set_defaults
    self.record_changes ||= {}
  end
end
