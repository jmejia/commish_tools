# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_super_admin!

    layout 'admin'

    private

    def require_super_admin!
      unless current_user&.super_admin?
        redirect_to root_path, alert: 'Access denied.'
      end
    end
  end
end
