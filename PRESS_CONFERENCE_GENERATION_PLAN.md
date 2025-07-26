# Press Conference Generation Plan

## 🚀 **CURRENT STATUS: ~80% COMPLETE**

✅ **WORKING:** Text generation, individual audio generation, UI, background jobs, status transitions  
❌ **MISSING:** Final audio assembly, download functionality, audio player  

## Overview
This feature allows league owners to create AI-generated press conferences for league members. The system will generate text responses using ChatGPT, convert them to audio using PlayHT, and stitch everything together into a complete press conference audio file.

## 📊 Implementation Progress

### ✅ **COMPLETED COMPONENTS**

**Database & Models:**
- ✅ PressConference model with status enum (`draft`, `generating`, `ready`)  
- ✅ PressConferenceQuestion with Active Storage `question_audio` attachment
- ✅ PressConferenceResponse with Active Storage `response_audio` attachment
- ✅ Migration for `final_audio_url` field
- ✅ Status transitions working correctly (draft → generating → ready)

**Background Jobs:**
- ✅ ChatgptResponseGenerationJob - Text generation with league context
- ✅ QuestionAudioGenerationJob - Announcer voice audio for questions  
- ✅ ResponseAudioGenerationJob - Cloned voice audio for responses
- ✅ Job integration - Text job triggers audio jobs automatically
- ✅ Status updates - Jobs properly update press conference status on completion

**API Integrations:**
- ✅ ChatgptClient - OpenAI API integration working
- ✅ PlayhtApiClient - Enhanced with TTS methods, authentication fixed
- ✅ Voice selection - Using real PlayHT voice IDs (Charles, Delilah, Benton, Samuel)

**User Interface:**
- ✅ Press conference creation form
- ✅ Press conference show page with questions/responses
- ✅ Status indicators and processing states
- ✅ League dashboard integration

### ❌ **MISSING COMPONENTS**

**Critical Missing:**
- ❌ AudioStitchingJob - No final audio assembly
- ❌ FFmpeg integration - No audio concatenation  
- ❌ Audio player functionality - UI exists but not wired up
- ❌ Download functionality - Button exists but not functional

**Technical Gaps:**
- ❌ Final audio file creation (Q1→R1→Q2→R2→Q3→R3)
- ❌ File cleanup and management
- ❌ Production S3 URL generation

### 🔧 **KNOWN ISSUES RESOLVED**
- ✅ PlayHT API authentication (fixed header format)
- ✅ Voice ID validation (updated to real voices)  
- ✅ Model relationships (fixed voice_clone access)
- ✅ Active Storage URL generation in development
- ✅ Status transition bug (fixed job not updating to 'ready')
- ✅ Test suite failures (fixed routing and job status issues)

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

### Database Schema Implementation

#### ✅ PressConference (IMPLEMENTED)
```ruby
# Current schema - press_conferences table
target_manager_id :bigint           # League member (target of press conference)
status :integer                     # enum: draft(0), generating(1), ready(2), archived(3)  
final_audio_url :string            # S3 URL for final stitched audio (ADDED)
week_number :integer               # Fantasy week
season_year :integer               # Fantasy season
league_id :bigint                  # Associated league

# Active Storage attachments:
has_one_attached :final_audio      # Complete press conference audio file
```

#### ✅ PressConferenceQuestion (IMPLEMENTED)  
```ruby
# Current schema - press_conference_questions table
question_text :text                 # The question text
question_audio_url :string         # S3 URL (for legacy/quick access)
playht_question_voice_id :string   # Which voice was used
order_index :integer               # Question order (0, 1, 2)

# Active Storage attachments:
has_one_attached :question_audio   # Individual question audio file
```

#### ✅ PressConferenceResponse (IMPLEMENTED)
```ruby
# Current schema - press_conference_responses table  
response_text :text                 # ChatGPT generated response
response_audio_url :string         # S3 URL (for legacy/quick access)
generation_prompt :text            # Prompt used for ChatGPT

# Active Storage attachments:
has_one_attached :response_audio   # Individual response audio file
```

### Background Job Workflow (CURRENT IMPLEMENTATION)

#### 1. ✅ ChatgptResponseGenerationJob (IMPLEMENTED)
- **Purpose**: Generate text responses for questions and trigger audio generation
- **Input**: `press_conference_id`
- **Process**:
  - Update status to `generating`
  - Retrieve hardcoded league context (fantasy football personalities)
  - For each question, call ChatGPT API to generate response text
  - Store response text in `press_conference_responses` table
  - **NEW:** Automatically enqueue audio generation jobs
  - **NEW:** `QuestionAudioGenerationJob.perform_later(question.id)`
  - **NEW:** `ResponseAudioGenerationJob.perform_later(response.id)`
  - **FIXED:** Update status to `ready` after all responses generated

#### 2. ✅ QuestionAudioGenerationJob (IMPLEMENTED)
- **Purpose**: Generate announcer voice audio for each question
- **Input**: `press_conference_question_id`
- **Process**:
  - Select from professional announcer voices (Charles, Delilah, Benton, Samuel)
  - Call PlayHT API with correct authentication (`AUTHORIZATION` header)
  - Generate audio using `Play3.0-mini` or `PlayDialog` engine
  - Store audio using Active Storage (`has_one_attached :question_audio`)
  - Store URL for quick access (development skips URL generation)

#### 3. ✅ ResponseAudioGenerationJob (IMPLEMENTED)  
- **Purpose**: Generate cloned voice audio for each response
- **Input**: `press_conference_response_id`
- **Process**:
  - Get target manager's voice clone (`target_manager.voice_clone.playht_voice_id`)
  - Call PlayHT API using the cloned voice ID
  - Generate audio using `Play3.0-mini` engine for balance of quality/speed
  - Store audio using Active Storage (`has_one_attached :response_audio`)
  - Check if all audio complete and update press conference status to `ready`

#### 4. ❌ AudioStitchingJob (NOT IMPLEMENTED)
- **Purpose**: Combine all audio files into final press conference
- **Input**: `press_conference_id`
- **Process** (PLANNED):
  - Download all question and response audio files from Active Storage
  - Use FFmpeg to concatenate: Q1 → R1 → Q2 → R2 → Q3 → R3
  - Upload final file to S3 using Active Storage
  - Update press conference with final audio attachment
  - Mark press conference as fully `ready` with downloadable audio

**Current Job Flow:**
```
User creates press conference 
    ↓
ChatgptResponseGenerationJob (text generation)
    ↓ (triggers automatically)
QuestionAudioGenerationJob + ResponseAudioGenerationJob (parallel)
    ↓ (missing)
AudioStitchingJob (not implemented yet)
```

### API Integrations (CURRENT IMPLEMENTATION)

#### ✅ ChatGPT Integration (IMPLEMENTED)
```ruby
# app/models/chatgpt_client.rb - WORKING
class ChatgptClient
  def generate_response(question, league_context)
    # Uses OpenAI::Client with gpt-4 model
    # Includes fantasy football personality context
    # Returns realistic trash talk and confidence
  end
end

# Hardcoded League Context (ChatgptResponseGenerationJob::LEAGUE_CONTEXT):
{
  nature: "Fantasy football league with 12 competitive friends",
  tone: "Humorous but competitive, with light trash talk", 
  rivalries: "Focus on season-long rivalries and recent matchups",
  history: "League has been running for 5+ years with established personalities",
  response_style: "Confident, slightly cocky, but good-natured"
}
```

#### ✅ PlayHT Integration (IMPLEMENTED & ENHANCED)
```ruby
# app/models/playht_api_client.rb - WORKING
class PlayhtApiClient
  # FIXED: Authentication headers (AUTHORIZATION vs Authorization)
  # FIXED: Using real voice IDs from PlayHT API
  
  def generate_speech(text:, voice:, **options)
    # Uses /api/v2/tts/stream endpoint
    # Supports Play3.0-mini, PlayDialog engines
    # Returns binary audio data (MP3)
  end
  
  def list_voices
    # Gets available voices from PlayHT
  end
  
  def list_cloned_voices  
    # Gets user's cloned voices
  end
end

# Real Voice IDs Being Used:
ANNOUNCER_VOICES = {
  professional_male: "s3://voice-cloning-zero-shot/9f1ee23a-9108-4538-90be-8e62efc195b6/charlessaad/manifest.json", # Charles
  professional_female: "s3://voice-cloning-zero-shot/1afba232-fae0-4b69-9675-7f1aac69349f/delilahsaad/manifest.json", # Delilah  
  energetic_male: "s3://voice-cloning-zero-shot/b41d1a8c-2c99-4403-8262-5808bc67c3e0/bentonsaad/manifest.json", # Benton
  news_anchor: "s3://voice-cloning-zero-shot/36e9c53d-ca4e-4815-b5ed-9732be3839b4/samuelsaad/manifest.json" # Samuel
}
```

#### ❌ FFmpeg Integration (NOT IMPLEMENTED)  
```ruby
# app/models/audio_processor.rb - PLANNED
class AudioProcessor
  def stitch_press_conference(audio_files_in_order)
    # TODO: Use FFmpeg to concatenate audio files
    # TODO: Add silence padding between Q&A pairs
    # TODO: Return path to final file for Active Storage
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

## 🎯 Next Priorities (Updated Implementation Plan - January 2025)

### ✅ Recent Fixes
- Fixed ChatGPT response generation job to properly update status to 'ready'
- Fixed test suite routing issues for press conference deletion
- Resolved Turbo/Devise compatibility issues in test environment

### Immediate (Complete MVP)
1. **AudioStitchingJob** - Implement final audio assembly
   - Download individual audio files from Active Storage  
   - Use FFmpeg to concatenate Q1→R1→Q2→R2→Q3→R3
   - Upload final file using Active Storage
   - Update press conference status and trigger UI updates

2. **Audio Player Functionality** - Wire up existing UI
   - Connect audio player to actual audio files
   - Add play/pause controls
   - Display duration and progress

3. **Download Functionality** - Enable file downloads
   - Wire up "Download Audio" button to final audio file
   - Add individual Q&A audio downloads if needed

### Short Term (Polish)
4. **Error Handling & Recovery**
   - Better job failure recovery
   - User-friendly error messages
   - Retry mechanisms for API failures

5. **Production Testing**
   - Test S3 configuration in production
   - Verify audio generation at scale
   - Performance optimization

### Future Enhancements (Post-MVP)
6. **Advanced Audio Features**
   - Background music
   - Intro/outro segments  
   - Multiple voice options per question

7. **League Context Customization**
   - Custom league personalities
   - Configurable trash talk levels
   - League-specific inside jokes

## Implementation Phases (Updated)

### ✅ Phase 1: Core Functionality (80% COMPLETE)
- ✅ Basic press conference creation
- ✅ Text generation with ChatGPT  
- ✅ Individual audio generation with PlayHT
- ✅ Status management and transitions
- ❌ Final audio stitching (NEXT PRIORITY)

### Phase 2: Polish & UX (NEXT)
- Audio player and download functionality
- Error handling and recovery
- Status page improvements  
- Performance optimization

### Phase 3: Advanced Features (FUTURE)
- Custom league context
- Voice selection options
- Enhanced audio features 