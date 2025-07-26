class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @league_memberships = current_user.league_memberships.includes(:league, :voice_clone)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
