class VoiceClonesController < ApplicationController
  before_action :set_league_membership
  before_action :set_voice_clone, only: [:show, :edit, :update, :destroy]
  before_action :ensure_own_membership, only: [:new, :create, :edit, :update, :destroy]

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
        redirect_to league_league_membership_voice_clone_path(
          @league_membership.league, @league_membership, @voice_clone
        ), notice: I18n.t('controllers.voice_clones.upload_processing')
      else
        redirect_to league_league_membership_voice_clone_path(
          @league_membership.league, @league_membership, @voice_clone
        ), notice: I18n.t('controllers.voice_clones.created_upload_needed')
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @voice_clone.update(voice_clone_params)
      if @voice_clone.audio_file.attached? && voice_clone_params[:audio_file].present?
        VoiceProcessingJob.perform_later(@voice_clone.id)
        redirect_to league_league_membership_voice_clone_path(
          @league_membership.league, @league_membership, @voice_clone
        ), notice: I18n.t('controllers.voice_clones.update_processing')
      else
        redirect_to league_league_membership_voice_clone_path(
          @league_membership.league, @league_membership, @voice_clone
        ), notice: I18n.t('controllers.voice_clones.update_success')
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @voice_clone.destroy
    redirect_to profile_path, notice: I18n.t('controllers.voice_clones.delete_success')
  end

  private

  def set_league_membership
    @league_membership = LeagueMembership.find(params[:league_membership_id])
  end

  def set_voice_clone
    @voice_clone = @league_membership.voice_clone || @league_membership.build_voice_clone
  end

  def ensure_own_membership
    unless @league_membership.user == current_user
      redirect_to league_path(@league_membership.league), alert: I18n.t('controllers.voice_clones.unauthorized')
    end
  end

  def voice_clone_params
    params.expect(voice_clone: [:audio_file])
  end
end
