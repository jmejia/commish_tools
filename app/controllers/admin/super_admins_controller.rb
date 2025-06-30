# frozen_string_literal: true

module Admin
  class SuperAdminsController < BaseController
    def index
      @super_admins = SuperAdmin.includes(:user).all
      @users = User.where.not(id: SuperAdmin.select(:user_id))
    end

    def create
      @user = User.find(params[:user_id])
      @super_admin = SuperAdmin.new(user: @user)

      if @super_admin.save
        redirect_to admin_super_admins_path, notice: "#{@user.display_name} is now a super admin."
      else
        redirect_to admin_super_admins_path, alert: "Failed to make #{@user.display_name} a super admin."
      end
    end

    def destroy
      @super_admin = SuperAdmin.find(params[:id])
      user_name = @super_admin.user.display_name

      @super_admin.destroy
      redirect_to admin_super_admins_path, notice: "#{user_name} is no longer a super admin."
    end
  end
end
