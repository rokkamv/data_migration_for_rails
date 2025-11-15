module DataMigration
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :change_role]

    def index
      @users = policy_scope(User).order(created_at: :desc)
      authorize User
    end

    def show
      authorize @user
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      if @user.update(user_params)
        redirect_to @user, notice: 'User was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user

      if @user.migration_executions.any?
        redirect_to @user, alert: 'Cannot delete user with execution history.'
      elsif @user.destroy
        redirect_to users_url, notice: 'User was successfully deleted.'
      else
        redirect_to @user, alert: 'Failed to delete user.'
      end
    end

    def change_role
      authorize @user

      if @user.update(role: params[:role])
        redirect_to @user, notice: "User role changed to #{@user.role.titleize}."
      else
        redirect_to @user, alert: 'Failed to change user role.'
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email)
    end
  end
end
