class MigrationPlan < ApplicationRecord
  # Serialization
  serialize :settings, coder: JSON

  # Associations
  has_many :migration_steps, dependent: :destroy
  has_many :migration_executions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true

  # Callbacks to set defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :ordered_by_name, -> { order(:name) }

  # Instance methods
  def can_be_deleted?
    migration_executions.empty?
  end

  def last_execution
    migration_executions.recent.first
  end

  private

  def set_defaults
    self.settings ||= {}
  end
end
