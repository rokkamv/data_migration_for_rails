# frozen_string_literal: true

module DataMigration
  class UserPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.all
      end
    end

    def index?
      user.admin?
    end

    def create?
      user.admin?
    end

    def update?
      user.admin?
    end

    def destroy?
      user.admin? && record != user # Can't delete yourself
    end
  end
end
