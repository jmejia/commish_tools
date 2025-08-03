class VoiceUploadLinksController < ApplicationController
  before_action :set_voice_clone
  before_action :ensure_league_owner

  def index
    @voice_upload_links = @voice_clone.voice_upload_links
  end

  def new
    @voice_upload_link = @voice_clone.voice_upload_links.build
  end

  def create
    @voice_upload_link = @voice_clone.voice_upload_links.build(voice_upload_link_params)
    if @voice_upload_link.save
      redirect_to league_league_membership_voice_clone_voice_upload_links_path(@voice_clone.league, @voice_clone.league_membership, @voice_clone),
notice: 'Shareable upload link created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @voice_upload_link = @voice_clone.voice_upload_links.find(params[:id])
    @voice_upload_link.destroy
    redirect_to league_league_membership_voice_clone_voice_upload_links_path(@voice_clone.league, @voice_clone.league_membership, @voice_clone),
notice: 'Shareable upload link deleted.'
  end

  private

  def set_voice_clone
    @voice_clone = VoiceClone.find(params[:voice_clone_id])
  end

  def ensure_league_owner
    unless @voice_clone.league.owner == current_user
      redirect_to league_path(@voice_clone.league), alert: 'Only the league owner can manage upload links.'
    end
  end

  def voice_upload_link_params
    params.expect(voice_upload_link: [:title, :instructions, :expires_at, :active, :max_uploads])
  end
end
