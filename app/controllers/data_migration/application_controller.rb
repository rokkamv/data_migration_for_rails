module DataMigration
  class ApplicationController < ActionController::Base
    include Pundit::Authorization
    include DataMigration::Engine.routes.url_helpers

    layout "data_migration"

    before_action :authenticate_user!

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    # Make engine routes available as default in views
    helper DataMigration::Engine.routes.url_helpers
    helper_method :main_app

    # Helper method to get engine root path
    def after_sign_in_path_for(resource)
      stored_location_for(resource) || root_path
    end

    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    # Provide access to host app routes if needed
    def main_app
      Rails.application.class.routes.url_helpers
    end

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end
