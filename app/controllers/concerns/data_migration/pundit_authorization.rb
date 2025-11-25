# frozen_string_literal: true

module DataMigration
  module PunditAuthorization
    extend ActiveSupport::Concern

    included do
      after_action :verify_authorized, except: :index
      after_action :verify_policy_scoped, only: :index
    end
  end
end
