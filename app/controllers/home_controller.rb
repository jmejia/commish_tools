# Handles the homepage and user redirections based on authentication and league ownership.
class HomeController < ApplicationController
  def index
    return unless user_signed_in?

    # Redirect authenticated users to their leagues or dashboard
    if current_user.league_owner?
      redirect_to leagues_path
    else
      user_leagues = current_user.leagues
      redirect_to leagues_path if user_leagues.any?
    end
  end
end
