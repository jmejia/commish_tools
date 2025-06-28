class HomeController < ApplicationController
  def index
    return unless user_signed_in?
    
    # Redirect authenticated users to their leagues or dashboard
    if current_user.league_owner?
      redirect_to leagues_path
    elsif current_user.leagues.any?
      redirect_to league_path(current_user.leagues.first)
    end
  end
end
