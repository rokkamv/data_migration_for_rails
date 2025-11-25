# frozen_string_literal: true

class MigrationPlan < ApplicationRecord
  # Associations
  belongs_to :user, class_name: 'DataMigrationUser'
  has_many :migration_steps, dependent: :destroy
  has_many :migration_executions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :ordered_by_name, -> { order(:name) }

  # Instance methods
  def can_be_deleted?
    migration_executions.empty?
  end

  def last_execution
    migration_executions.recent.first
  end
end
