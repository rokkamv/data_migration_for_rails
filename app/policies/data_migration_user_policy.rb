# frozen_string_literal: true

class DataMigrationUserPolicy < ApplicationPolicy
  def index?
    user.can_manage_users?
  end

  def show?
    user.can_manage_users? || record.id == user.id # Users can view their own profile
  end

  def create?
    user.can_manage_users?
  end

  def update?
    user.can_manage_users? || record.id == user.id # Users can update their own profile
  end

  def destroy?
    user.can_manage_users? && record.id != user.id # Can't delete yourself
  end

  def change_role?
    user.can_manage_users? && record.id != user.id # Can't change your own role
  end

  class Scope < Scope
    def resolve
      if user.can_manage_users?
        scope.all # Admins see all users
      else
        scope.where(id: user.id) # Others only see themselves
      end
    end
  end
end
