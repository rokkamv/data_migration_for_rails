module DataMigration
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    # Devise authentication
    before_action :authenticate_user!, unless: :devise_controller?

    # Pundit authorization
    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    # Layout
    layout 'data_migration'

    # Make engine route helpers available in views
    helper DataMigration::Engine.routes.url_helpers

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || '/data_migration/migration_plans')
    end

    # Devise helpers are automatically available as:
    # - current_user (from devise_for :users)
    # - user_signed_in? (from devise_for :users)
    # No need to override since resource name is :users

    # Override Devise redirect after sign in
    def after_sign_in_path_for(resource)
      '/data_migration/migration_plans'
    end

    # Handle CSRF token verification failures for Devise controllers
    # This prevents errors when Devise's FailureApp redirects after failed login
    def handle_unverified_request
      if devise_controller?
        sign_out if user_signed_in?
        flash[:alert] = "Session expired. Please sign in again."
        redirect_to new_user_session_path
      else
        super
      end
    end
  end
end
