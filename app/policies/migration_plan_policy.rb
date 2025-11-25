# frozen_string_literal: true

class MigrationPlanPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view plans
  end

  def show?
    true # All authenticated users can view a plan
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin? && record.can_be_deleted?
  end

  def execute?
    user.can_execute_migrations?
  end

  def export_config?
    true # All authenticated users can export plan configuration
  end

  def import_config?
    user.admin? # Only admins can import plan configurations
  end

  class Scope < Scope
    def resolve
      scope.all # All users can see all plans
    end
  end
end
