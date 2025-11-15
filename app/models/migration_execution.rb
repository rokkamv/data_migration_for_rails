class MigrationExecution < ApplicationRecord
  # Serialization
  serialize :stats, coder: JSON

  # Associations
  belongs_to :migration_plan
  belongs_to :user
  has_many :migration_records, dependent: :destroy

  # Enums
  enum execution_type: { export: 0, import: 1 }
  enum status: { pending: 0, running: 1, completed: 2, failed: 3 }

  # Validations
  validates :execution_type, presence: true
  validates :status, presence: true

  # Callbacks to set defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_plan, ->(plan) { where(migration_plan: plan) }

  # Instance methods
  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end

  def progress_percentage
    return 0 if stats.blank? || stats['total'].to_i.zero?
    ((stats['processed'].to_f / stats['total'].to_f) * 100).round(2)
  end

  def display_name
    "#{execution_type.titleize} - #{migration_plan.name}"
  end

  private

  def set_defaults
    self.stats ||= {}
  end
end
