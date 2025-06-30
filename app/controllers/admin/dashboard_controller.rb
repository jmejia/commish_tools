# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @user_count = User.count
      @super_admin_count = SuperAdmin.count
      @league_count = League.count
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end
