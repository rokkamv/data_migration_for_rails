class MigrationExecution < ApplicationRecord
  # Associations
  belongs_to :migration_plan
  belongs_to :user, class_name: 'DataMigrationUser'
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

  # Custom getter for filter_params
  def filter_params
    value = read_attribute(:filter_params)
    return {} if value.blank?
    return value if value.is_a?(Hash)

    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse filter_params for MigrationExecution #{id}: #{e.message}"
    {}
  end

  # Custom setter for filter_params
  def filter_params=(value)
    if value.is_a?(String)
      write_attribute(:filter_params, value)
    elsif value.is_a?(Hash)
      write_attribute(:filter_params, value.to_json)
    else
      write_attribute(:filter_params, {}.to_json)
    end
  end

  # Custom getter for stats
  def stats
    value = read_attribute(:stats)
    return {} if value.blank?
    return value if value.is_a?(Hash)

    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse stats for MigrationExecution #{id}: #{e.message}"
    {}
  end

  # Custom setter for stats
  def stats=(value)
    if value.is_a?(String)
      write_attribute(:stats, value)
    elsif value.is_a?(Hash)
      write_attribute(:stats, value.to_json)
    else
      write_attribute(:stats, {}.to_json)
    end
  end

  private

  def set_defaults
    # Defaults are handled by getters
  end
end
