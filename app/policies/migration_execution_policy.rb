# frozen_string_literal: true

class MigrationExecutionPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view execution history
  end

  def show?
    true # All authenticated users can view execution details
  end

  def create?
    user.can_execute_migrations?
  end

  def download?
    true # All authenticated users can download exports
  end

  def cancel?
    user.can_execute_migrations? && record.running?
  end

  class Scope < Scope
    def resolve
      if user.viewer?
        scope.where(status: %i[completed failed]) # Viewers only see finished executions
      else
        scope.all # Operators and admins see everything including running
      end
    end
  end
end
