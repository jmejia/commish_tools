# Audio processing utility for concatenating press conference audio files
# Uses FFmpeg to stitch question and response audio into final press conference
class AudioProcessor
  require 'streamio-ffmpeg'
  
  # Concatenates question and response audio files in proper order
  # @param press_conference [PressConference] The press conference to process
  # @return [String] Path to the final concatenated audio file
  def self.stitch_press_conference(press_conference)
    new(press_conference).stitch_audio_files
  end
  
  def initialize(press_conference)
    @press_conference = press_conference
    @temp_files = []
    @silence_duration = 2.0 # seconds of silence between segments
  end
  
  def stitch_audio_files
    validate_inputs
    download_audio_files
    create_final_audio
  ensure
    cleanup_temp_files
  end
  
  private
  
  def validate_inputs
    unless all_audio_files_present?
      raise "Cannot stitch audio: missing audio files for press conference #{@press_conference.id}"
    end
    
    unless ffmpeg_available?
      raise "FFmpeg not available - cannot process audio"
    end
  end
  
  def all_audio_files_present?
    questions_with_audio = @press_conference.press_conference_questions.all? do |q|
      q.question_audio.attached?
    end
    
    responses_with_audio = @press_conference.press_conference_questions.all? do |q|
      q.press_conference_response&.response_audio&.attached?
    end
    
    questions_with_audio && responses_with_audio
  end
  
  def ffmpeg_available?
    FFMPEG.ffmpeg_binary.present?
  rescue StandardError
    false
  end
  
  def download_audio_files
    @press_conference.press_conference_questions.order(:order_index).each do |question|
      # Download question audio
      question_temp_file = download_audio_file(question.question_audio, "question_#{question.id}")
      @temp_files << { type: :question, file: question_temp_file, order: question.order_index }
      
      # Download response audio
      if question.press_conference_response&.response_audio&.attached?
        response_temp_file = download_audio_file(
          question.press_conference_response.response_audio, 
          "response_#{question.press_conference_response.id}"
        )
        @temp_files << { type: :response, file: response_temp_file, order: question.order_index }
      end
    end
    
    Rails.logger.info "Downloaded #{@temp_files.length} audio files for press conference #{@press_conference.id}"
  end
  
  def download_audio_file(audio_attachment, prefix)
    temp_file = Tempfile.new([prefix, '.mp3'])
    temp_file.binmode
    
    audio_attachment.download do |chunk|
      temp_file.write(chunk)
    end
    
    temp_file.rewind
    temp_file
  end
  
  def create_final_audio
    final_temp_file = Tempfile.new(['final_press_conference', '.mp3'])
    final_temp_file.close # Close so FFmpeg can write to it
    
    if @temp_files.length == 2
      # Simple case: just one question and response
      concatenate_two_files(final_temp_file.path)
    else
      # Complex case: multiple Q&A pairs with silence
      concatenate_with_silence(final_temp_file.path)
    end
    
    Rails.logger.info "Created final audio file: #{final_temp_file.path} (#{File.size(final_temp_file.path)} bytes)"
    final_temp_file.path
  end
  
  def concatenate_two_files(output_path)
    # Simple concatenation for two files
    input_files = @temp_files.sort_by { |f| [f[:order], f[:type] == :question ? 0 : 1] }
    
    movie1 = FFMPEG::Movie.new(input_files[0][:file].path)
    movie2 = FFMPEG::Movie.new(input_files[1][:file].path)
    
    # Create concat demuxer input
    concat_list = create_concat_list(input_files.map { |f| f[:file].path })
    
    movie1.transcode(output_path, {
      custom: ['-f', 'concat', '-safe', '0', '-i', concat_list, '-c', 'copy']
    })
  ensure
    File.unlink(concat_list) if concat_list && File.exist?(concat_list)
  end
  
  def concatenate_with_silence(output_path)
    # Complex concatenation with silence between segments
    ordered_files = @temp_files.sort_by { |f| [f[:order], f[:type] == :question ? 0 : 1] }
    
    # Build filter complex for concatenation with silence
    filter_parts = []
    input_parts = []
    
    ordered_files.each_with_index do |file_info, index|
      input_parts << '-i'
      input_parts << file_info[:file].path
      
      # Add silence after each file except the last
      if index < ordered_files.length - 1
        filter_parts << "[#{index}:a]"
        filter_parts << "[#{index + ordered_files.length}:a]" # Silence input
      else
        filter_parts << "[#{index}:a]"
      end
    end
    
    # Generate silence files
    silence_files = generate_silence_files(ordered_files.length - 1)
    silence_files.each { |silence| input_parts << '-i' << silence }
    
    # Create filter complex
    filter_complex = filter_parts.join('') + "concat=n=#{filter_parts.length}:v=0:a=1[out]"
    
    # Use first file as base for transcoding
    first_movie = FFMPEG::Movie.new(ordered_files[0][:file].path)
    
    custom_options = input_parts[2..-1] + [  # Skip first -i since it's handled by streamio-ffmpeg
      '-filter_complex', filter_complex,
      '-map', '[out]',
      '-c:a', 'mp3'
    ]
    
    first_movie.transcode(output_path, { custom: custom_options })
  ensure
    silence_files&.each { |file| File.unlink(file) if File.exist?(file) }
  end
  
  def create_concat_list(file_paths)
    concat_file = Tempfile.new(['concat_list', '.txt'])
    concat_file.write(file_paths.map { |path| "file '#{path}'" }.join("\n"))
    concat_file.close
    concat_file.path
  end
  
  def generate_silence_files(count)
    silence_files = []
    
    count.times do |i|
      silence_file = Tempfile.new(["silence_#{i}", '.mp3'])
      silence_file.close
      
      # Generate silence using FFmpeg
      system('ffmpeg', '-f', 'lavfi', '-i', "anullsrc=channel_layout=stereo:sample_rate=44100", 
             '-t', @silence_duration.to_s, '-c:a', 'mp3', silence_file.path, 
             '-y', '-loglevel', 'quiet')
      
      silence_files << silence_file.path
    end
    
    silence_files
  end
  
  def cleanup_temp_files
    @temp_files.each do |file_info|
      temp_file = file_info[:file]
      temp_file&.close
      temp_file&.unlink
    end
    @temp_files.clear
  end
end