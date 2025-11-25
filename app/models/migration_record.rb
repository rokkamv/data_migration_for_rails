# frozen_string_literal: true

class MigrationRecord < ApplicationRecord
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

  # Custom getter for record_changes
  def record_changes
    value = read_attribute(:record_changes)
    return {} if value.blank?
    return value if value.is_a?(Hash)

    JSON.parse(value)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse record_changes for MigrationRecord #{id}: #{e.message}"
    {}
  end

  # Custom setter for record_changes
  def record_changes=(value)
    if value.is_a?(String)
      write_attribute(:record_changes, value)
    elsif value.is_a?(Hash)
      write_attribute(:record_changes, value.to_json)
    else
      write_attribute(:record_changes, {}.to_json)
    end
  end

  # Instance methods
  def display_name
    "#{migrated_model_name} #{record_identifier}"
  end

  def success?
    !failed?
  end

  private

  def set_defaults
    # Defaults are handled by getters
  end
end
