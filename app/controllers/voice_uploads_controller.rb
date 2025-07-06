class VoiceUploadsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :create], raise: false
  before_action :set_voice_upload_link, only: [:show, :create]

  # Show the upload form
  def show
  end

  # Process the upload
  def create
    audio_file = params.dig(:voice_clone, :original_audio)

    if audio_file.blank?
      flash.now[:alert] = "Please select a file to upload."
      return render :show, status: :unprocessable_entity
    end

    # Use the existing voice_clone from the link
    @voice_clone = @voice_upload_link.voice_clone

    if @voice_clone.update(original_audio: audio_file)
      @voice_upload_link.increment!(:upload_count)
      
      redirect_to root_path, notice: "Voice sample uploaded successfully. Thank you!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_voice_upload_link
    @voice_upload_link = VoiceUploadLink.find_by!(public_token: params[:public_token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid upload link."
  end
end 