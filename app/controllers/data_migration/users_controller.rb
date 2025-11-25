# frozen_string_literal: true

module DataMigration
  class UsersController < ApplicationController
    include DataMigration::PunditAuthorization

    before_action :set_user, only: %i[edit update destroy]

    def index
      authorize DataMigrationUser
      @users = policy_scope(DataMigrationUser).ordered_by_email
    end

    def new
      authorize DataMigrationUser
      @user = DataMigrationUser.new
    end

    def create
      authorize DataMigrationUser
      @user = DataMigrationUser.new(user_params)

      if @user.save
        redirect_to users_path, notice: 'User created successfully.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      # Remove password if blank
      params_to_update = if user_params[:password].blank?
                           user_params.except(:password, :password_confirmation)
                         else
                           user_params
                         end

      if @user.update(params_to_update)
        redirect_to users_path, notice: 'User updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user

      if @user.destroy
        redirect_to users_path, notice: 'User deleted successfully.'
      else
        redirect_to users_path, alert: @user.errors.full_messages.join(', ')
      end
    end

    private

    def set_user
      @user = DataMigrationUser.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
    end
  end
end
