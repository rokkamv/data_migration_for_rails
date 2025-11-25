# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # Skip CSRF verification for the new action to handle Devise FailureApp redirects
    skip_before_action :verify_authenticity_token, only: [:new]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
