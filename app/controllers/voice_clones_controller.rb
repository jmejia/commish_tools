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

  def edit
  end

  def create
    @voice_clone = @league_membership.build_voice_clone(voice_clone_params)

    if @voice_clone.save
      if @voice_clone.audio_file.attached?
        VoiceProcessingJob.perform_later(@voice_clone.id)
        redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone),
                    notice: 'Voice sample uploaded successfully and is being processed.'
      else
        redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone),
                    notice: 'Voice clone created. Please upload an audio file to begin processing.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @voice_clone.update(voice_clone_params)
      if @voice_clone.audio_file.attached? && voice_clone_params[:audio_file].present?
        VoiceProcessingJob.perform_later(@voice_clone.id)
        redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone),
                    notice: 'Voice sample updated successfully and is being processed.'
      else
        redirect_to league_league_membership_voice_clone_path(@league_membership.league, @league_membership, @voice_clone),
                    notice: 'Voice clone updated successfully.'
      end
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
