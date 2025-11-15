class MigrationStepPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view steps
  end

  def show?
    true
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
