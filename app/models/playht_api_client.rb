class PlayhtApiClient
  BASE_URL = "https://api.play.ht/api/v2"
  USER_AGENT = "PlayHT Ruby Client/1.0"

  # Custom error classes following Octokit pattern
  class Error < StandardError; end

  class ClientError < Error; end

  class ServerError < Error; end

  class BadRequest < ClientError; end

  class Unauthorized < ClientError; end

  class Forbidden < ClientError; end

  class NotFound < ClientError; end

  class TooManyRequests < ClientError; end

  class InternalServerError < ServerError; end

  class BadGateway < ServerError; end

  class ServiceUnavailable < ServerError; end

  class GatewayTimeout < ServerError; end

  def initialize(user_id:, api_key:)
    @user_id = user_id
    @api_key = api_key
    @connection = build_connection
  end

  def create_voice_clone_from_upload(file_path:, voice_name:)
    response = @connection.post('cloned-voices/instant') do |req|
      req.body = {
        sample_file: Faraday::Multipart::FilePart.new(file_path, 'audio/mpeg'),
        voice_name: voice_name,
      }
    end
    response.body
  end

  # Generate speech from text using PlayHT's TTS API
  # @param text [String] The text to convert to speech
  # @param voice [String] The voice ID or voice clone ID to use
  # @param options [Hash] Additional options (voice_engine, output_format, speed, etc.)
  # @return [String] Binary audio data
  def generate_speech(text:, voice:, **options)
    default_options = {
      voice_engine: "Play3.0-mini",
      output_format: "mp3",
      speed: 1.0,
      sample_rate: 24000
    }
    
    body = default_options.merge(options).merge(
      text: text,
      voice: voice
    )
    
    response = @connection.post('tts/stream') do |req|
      req.headers['Accept'] = 'audio/mpeg'
      req.body = body
    end
    
    # Return the binary audio data
    response.body
  end

  # Generate speech using streaming API for lower latency
  # @param text [String] The text to convert to speech
  # @param voice [String] The voice ID or voice clone ID to use
  # @param options [Hash] Additional options
  # @return [String] Binary audio data
  def generate_speech_stream(text:, voice:, **options)
    default_options = {
      voice_engine: "Play3.0-mini",
      output_format: "mp3",
      speed: 1.0,
      sample_rate: 24000
    }
    
    body = default_options.merge(options).merge(
      text: text,
      voice: voice
    )
    
    response = @connection.post('tts/stream') do |req|
      req.headers['Accept'] = 'audio/mpeg'
      req.body = body
    end
    
    # Return the binary audio data
    response.body
  end

  # Get list of available stock voices
  def list_voices
    response = @connection.get('voices')
    response.body
  end

  # Get user's cloned voices
  def list_cloned_voices
    response = @connection.get('cloned-voices')
    response.body
  end

  private

  def build_connection
    Faraday.new(url: BASE_URL, headers: default_headers) do |builder|
      # Request middleware
      builder.request :multipart
      builder.request :json
      builder.request :retry, max: 3, interval: 0.5, backoff_factor: 2, exceptions: [
        Faraday::ConnectionFailed,
        Faraday::TimeoutError,
        ServerError,
      ]

      # Response middleware
      builder.response :json
      builder.response :raise_error do |env|
        case env[:status]
        when 400
          raise BadRequest, error_message(env)
        when 401
          raise Unauthorized, error_message(env)
        when 403
          raise Forbidden, error_message(env)
        when 404
          raise NotFound, error_message(env)
        when 429
          raise TooManyRequests, error_message(env)
        when 500
          raise InternalServerError, error_message(env)
        when 502
          raise BadGateway, error_message(env)
        when 503
          raise ServiceUnavailable, error_message(env)
        when 504
          raise GatewayTimeout, error_message(env)
        when 400..499
          raise ClientError, error_message(env)
        when 500..599
          raise ServerError, error_message(env)
        end
      end

      # Logging middleware
      builder.response :logger, Rails.logger, headers: true, bodies: true do |logger|
        logger.filter(/(Authorization: "Bearer) (.+)(")/i, '\1 [REDACTED]\3')
        logger.filter(/(X-User-ID: ")(.+)(")/i, '\1[REDACTED]\3')
      end

      # Use default adapter
      builder.adapter Faraday.default_adapter
    end
  end

  def default_headers
    {
      'AUTHORIZATION' => @api_key,
      'X-USER-ID' => @user_id,
      'Accept' => 'application/json',
      'User-Agent' => USER_AGENT,
    }
  end

  def error_message(env)
    body = env[:body]
    if body.is_a?(Hash) && body['message']
      "#{env[:status]}: #{body['message']}"
    else
      "#{env[:status]}: #{env[:reason_phrase]}"
    end
  end
end
