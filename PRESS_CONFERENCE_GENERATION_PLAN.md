# Press Conference Generation Plan

## Overview
This feature allows league owners to create AI-generated press conferences for league members. The system will generate text responses using ChatGPT, convert them to audio using PlayHT, and stitch everything together into a complete press conference audio file.

## User Flow

### 1. Initiation
- League owner navigates to league dashboard
- Clicks "Create New" button in press conference section
- Redirected to press conference creation form

### 2. Configuration
- Select league member for the press conference
- Enter three questions (required)
- Submit form to start generation process

### 3. Background Processing
- User sees "Processing..." status page
- Background jobs handle the complex workflow
- User can check status or receive notification when complete

### 4. Completion
- Final audio file is available for download/playback
- Press conference appears in league dashboard with all components

## Technical Architecture

### Database Schema Changes

#### New Fields for PressConference
```ruby
# Migration needed for press_conferences table
add_column :press_conferences, :league_member_id, :integer # who the conference is about
add_column :press_conferences, :league_context, :text # hardcoded context for now
add_column :press_conferences, :status, :string, default: 'draft' # draft, processing, completed, failed
add_column :press_conferences, :final_audio_url, :string # S3 URL for final stitched audio
add_column :press_conferences, :processing_started_at, :datetime
add_column :press_conferences, :processing_completed_at, :datetime
add_column :press_conferences, :error_message, :text
```

#### New Fields for PressConferenceQuestion
```ruby
# Migration needed for press_conference_questions table
add_column :press_conference_questions, :question_audio_url, :string # PlayHT generated audio
add_column :press_conference_questions, :question_voice_id, :string # which voice was used
add_column :press_conference_questions, :processing_status, :string, default: 'pending'
```

#### New Fields for PressConferenceResponse
```ruby
# Migration needed for press_conference_responses table
add_column :press_conference_responses, :response_audio_url, :string # PlayHT generated audio
add_column :press_conference_responses, :processing_status, :string, default: 'pending'
```

### Background Job Workflow

#### 1. PressConferenceGenerationJob (Orchestrator)
- **Purpose**: Coordinates the entire workflow
- **Responsibilities**:
  - Update press conference status to 'processing'
  - Generate responses using ChatGPT
  - Generate question audio using PlayHT
  - Generate response audio using PlayHT
  - Stitch final audio using FFmpeg
  - Update final status

#### 2. ChatGptResponseGenerationJob
- **Purpose**: Generate text responses for questions
- **Input**: press_conference_id, question_ids
- **Process**:
  - Retrieve hardcoded league context
  - For each question, call ChatGPT API
  - Store response text in press_conference_responses table
  - Mark question as 'text_complete'

#### 3. QuestionAudioGenerationJob
- **Purpose**: Generate audio for each question
- **Input**: press_conference_question_ids
- **Process**:
  - Randomly select from pre-built voices (different per question)
  - Call PlayHT API for each question
  - Store audio URL in press_conference_questions table
  - Mark question as 'audio_complete'

#### 4. ResponseAudioGenerationJob
- **Purpose**: Generate audio for each response
- **Input**: press_conference_response_ids, cloned_voice_id
- **Process**:
  - Use the league member's cloned voice
  - Call PlayHT API for each response
  - Store audio URL in press_conference_responses table
  - Mark response as 'audio_complete'

#### 5. AudioStitchingJob
- **Purpose**: Combine all audio files into final press conference
- **Input**: press_conference_id
- **Process**:
  - Download all question and response audio files
  - Use FFmpeg to concatenate: Q1 -> R1 -> Q2 -> R2 -> Q3 -> R3
  - Upload final file to S3
  - Update press conference with final_audio_url
  - Mark press conference as 'completed'

### API Integrations

#### ChatGPT Integration
```ruby
# New class: app/models/chatgpt_client.rb
class ChatGptClient
  def generate_response(question, league_context)
    # Call OpenAI API with question and context
    # Return response text
  end
end
```

#### PlayHT Integration (Enhanced)
```ruby
# Enhance existing: app/models/playht_api_client.rb
class PlayhtApiClient
  def generate_question_audio(text, voice_id)
    # Generate audio for question using pre-built voice
  end
  
  def generate_response_audio(text, cloned_voice_id)
    # Generate audio for response using cloned voice
  end
end
```

#### FFmpeg Integration
```ruby
# New class: app/models/audio_processor.rb
class AudioProcessor
  def stitch_press_conference(audio_files_in_order)
    # Use FFmpeg to concatenate audio files
    # Return path to final file
  end
end
```

### Hardcoded League Context (Phase 1)
```ruby
# In PressConference model or as a constant
LEAGUE_CONTEXT = {
  nature: "Fantasy football league with 12 competitive friends",
  tone: "Humorous but competitive, with light trash talk",
  rivalries: "Focus on season-long rivalries and recent matchups",
  history: "League has been running for 5+ years with established personalities",
  response_style: "Confident, slightly cocky, but good-natured"
}
```

## Controller Changes

### LeaguesController
- Add `press_conferences` action to display press conference section
- Add redirect to press conference creation

### PressConferencesController (New)
```ruby
class PressConferencesController < ApplicationController
  def new
    # Show form to create new press conference
  end
  
  def create
    # Create press conference and start background processing
  end
  
  def show
    # Display press conference status/results
  end
  
  def status
    # API endpoint for checking processing status
  end
end
```

## View Changes

### League Dashboard (leagues/dashboard.html.erb)
- Add press conference section with:
  - List of existing press conferences
  - "Create New" button
  - Status indicators for processing conferences

### Press Conference Creation Form (press_conferences/new.html.erb)
- League member selection dropdown
- Three question input fields
- Submit button to start generation

### Press Conference Status Page (press_conferences/show.html.erb)
- Processing status indicator
- Progress through each step
- Final audio player when complete
- Download link for final audio

## Error Handling

### API Failures
- ChatGPT API rate limits/failures
- PlayHT API failures
- FFmpeg processing errors

### Recovery Strategies
- Retry logic for transient failures
- Partial completion tracking
- Manual intervention for stuck jobs

### User Communication
- Clear error messages
- Processing status updates
- Email notifications for completion/failure

## Testing Strategy

### Feature Test (TDD Starting Point)
```ruby
# spec/features/press_conference_generation_spec.rb
RSpec.describe "Press Conference Generation", type: :feature do
  scenario "League owner creates a new press conference" do
    # Test the entire happy path workflow
  end
end
```

### Unit Tests
- Model validations and associations
- Background job logic
- API client integrations
- Audio processing

### Integration Tests
- API client responses
- Background job workflows
- File upload/download

### System Tests
- Complete user workflow
- Error scenarios
- Status page updates

## Performance Considerations

### Background Processing
- Use Sidekiq for job queue
- Implement job priorities
- Monitor job failures

### File Storage
- Store audio files in S3
- Implement cleanup for temporary files
- Consider CDN for audio delivery

### Monitoring
- Track processing times
- Monitor API usage/costs
- Alert on failures

## Security Considerations

### Data Privacy
- Ensure league context doesn't contain sensitive data
- Secure API keys for external services
- Proper authorization for press conference access

### File Security
- Validate audio file types
- Sanitize file names
- Implement proper S3 permissions

## Deployment Considerations

### Environment Variables
- OpenAI API key
- PlayHT API credentials
- FFmpeg path configuration

### Dependencies
- FFmpeg installation
- Background job worker deployment
- File storage configuration

## Future Enhancements (Not in MVP)

### League Context Customization
- Allow league managers to edit league context
- Save custom contexts per league
- Context templates

### Voice Selection
- Let users choose from available voices
- Preview voice samples
- Custom voice preferences per league member

### Advanced Audio Features
- Background music
- Intro/outro segments
- Sound effects

### Analytics
- Track press conference popularity
- Monitor generation costs
- Usage statistics

## Success Metrics

### Technical Metrics
- Processing success rate > 95%
- Average processing time < 10 minutes
- API error rate < 5%

### User Metrics
- Press conferences created per league
- User satisfaction with generated content
- Feature adoption rate

## Implementation Phases

### Phase 1: Core Functionality
- Basic press conference creation
- Text generation with ChatGPT
- Audio generation with PlayHT
- Simple audio stitching

### Phase 2: Polish & UX
- Status page improvements
- Error handling
- User notifications
- Performance optimization

### Phase 3: Advanced Features
- Custom league context
- Voice selection
- Enhanced audio features 