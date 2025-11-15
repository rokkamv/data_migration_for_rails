class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Role-based access control
  enum role: { viewer: 0, operator: 1, admin: 2 }

  # Validations
  validates :role, presence: true

  # Associations
  has_many :migration_executions, dependent: :restrict_with_error

  # Permissions
  def can_execute_migrations?
    operator? || admin?
  end

  def can_manage_plans?
    admin?
  end

  def can_manage_users?
    admin?
  end
end
