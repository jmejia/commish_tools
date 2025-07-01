class VoiceClonesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league_membership
  before_action :set_voice_clone, only: [:show, :edit, :update, :destroy]
  before_action :ensure_league_owner, only: [:new, :create, :edit, :update, :destroy]

  def show
  end

  def new
    @voice_clone = @league_membership.build_voice_clone
  end

  def create
    @voice_clone = @league_membership.build_voice_clone(voice_clone_params)
    
    if @voice_clone.save
      VoiceProcessingJob.perform_later(@voice_clone.id) if @voice_clone.audio_file.attached?
      redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone), 
                  notice: 'Voice sample uploaded successfully and is being processed.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @voice_clone.update(voice_clone_params)
      VoiceProcessingJob.perform_later(@voice_clone.id) if @voice_clone.audio_file.attached? && @voice_clone.audio_file.attached_changes.present?
      redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone), 
                  notice: 'Voice sample updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @voice_clone.destroy
    redirect_to league_path(@league_membership.league), notice: 'Voice clone deleted successfully.'
  end

  private

  def set_league_membership
    @league_membership = LeagueMembership.find(params[:league_membership_id])
  end

  def set_voice_clone
    @voice_clone = @league_membership.voice_clone || @league_membership.build_voice_clone
  end

  def ensure_league_owner
    unless @league_membership.league.owner == current_user
      redirect_to league_path(@league_membership.league), alert: 'Only the league owner can manage voice clones.'
    end
  end

  def voice_clone_params
    params.require(:voice_clone).permit(:audio_file)
  end
end