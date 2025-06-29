# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    def index
      @users = User.includes(:super_admin).order(:created_at)
    end

    def show
      @user = User.find(params[:id])
    end
  end
end
