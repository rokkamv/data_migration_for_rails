# frozen_string_literal: true

class DataMigrationUser < ApplicationRecord
  self.table_name = 'data_migration_users'

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :migration_plans, dependent: :restrict_with_error
  has_many :migration_executions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true

  # Role enum
  enum role: { viewer: 0, operator: 1, admin: 2 }

  # Callbacks
  after_initialize :set_default_role, if: :new_record?

  # Scopes
  scope :ordered_by_email, -> { order(:email) }
  scope :admins, -> { where(role: :admin) }
  scope :operators, -> { where(role: :operator) }
  scope :viewers, -> { where(role: :viewer) }

  # Permission methods
  def can_execute_migrations?
    operator? || admin?
  end

  def can_manage_users?
    admin?
  end

  private

  def set_default_role
    self.role ||= :viewer
  end
end
