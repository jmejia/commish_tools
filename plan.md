# Fantasy Football Commissioner App - Project Plan

## Project Overview

A web application for fantasy football commissioners using the Sleeper platform, featuring AI-generated press conferences with cloned voices of league managers. The app will create entertaining press conferences for the lowest-scoring team each week, using ChatGPT for responses and PlayHT for voice cloning and audio generation.

## Tech Stack

- **Backend**: Rails 8
- **Database**: PostgreSQL
- **Frontend**: Stimulus + Hotwire + Tailwind CSS
- **Audio Processing**: FFmpeg (for audio conversion and stitching)
- **Testing**: RSpec-rails + FactoryBot
- **Deployment**: Heroku
- **File Storage**: AWS S3
- **APIs**: 
  - Sleeper API (fantasy data)
  - ChatGPT API (AI responses)
  - PlayHT API (voice cloning & audio generation)
- **Browser APIs**:
  - MediaRecorder API (voice recording)
  - Web Audio API (audio playback and processing)

## Core Features

### 1. User Management & Authentication
- **League Owners**: Full league management capabilities
- **Team Managers**: Limited to their own voice and content
- **Authentication**: Devise for user management
- **Authorization**: Role-based access control

### 2. League Integration
- Connect with Sleeper API to fetch:
  - League data and settings
  - Manager information
  - Weekly scores and matchups
  - Player statistics
  - Historical data for context

### 3. Voice Cloning System
- Voice sample upload (league owners can upload for any manager)
- Browser-based voice recording using MediaRecorder API
- Audio format conversion and optimization using FFmpeg
- Integration with PlayHT API for voice cloning
- Storage of voice clone references in database
- Secure link generation for managers to upload their own voices
- In-browser audio playback and preview capabilities

### 4. Press Conference Generation
- Automatic identification of lowest-scoring team each week
- Commissioner input for custom questions
- ChatGPT integration with league context
- Audio generation using cloned voices
- Multiple question voices from PlayHT standard library
- FFmpeg audio stitching to create complete press conference files
- In-browser audio player for press conference playback

### 5. Content Management
- Press conference history and archives
- Voice sample management
- League-specific content isolation
- 404 protection for unauthorized access

## Database Schema

### Users Table
```sql
- id (primary key)
- email
- encrypted_password
- first_name
- last_name
- role (enum: league_owner, team_manager)
- created_at
- updated_at
```

### Leagues Table
```sql
- id (primary key)
- sleeper_league_id (unique)
- name
- season_year
- owner_id (foreign key to users)
- settings (jsonb - league configuration)
- created_at
- updated_at
```

### League Memberships Table
```sql
- id (primary key)
- league_id (foreign key)
- user_id (foreign key)
- sleeper_user_id
- team_name
- role (enum: owner, manager)
- created_at
- updated_at
```

### Voice Clones Table
```sql
- id (primary key)
- league_membership_id (foreign key)
- playht_voice_id
- original_audio_url (S3 path)
- status (enum: pending, processing, ready, failed)
- upload_token (for secure uploads)
- created_at
- updated_at
```

### Press Conferences Table
```sql
- id (primary key)
- league_id (foreign key)
- target_manager_id (foreign key to league_memberships)
- week_number
- season_year
- status (enum: draft, generating, ready, archived)
- context_data (jsonb - scores, matchups, stats)
- created_at
- updated_at
```

### Press Conference Questions Table
```sql
- id (primary key)
- press_conference_id (foreign key)
- question_text
- question_audio_url (S3 path)
- playht_question_voice_id
- order_index
- created_at
- updated_at
```

### Press Conference Responses Table
```sql
- id (primary key)
- question_id (foreign key)
- response_text
- response_audio_url (S3 path)
- generation_prompt (stored for debugging)
- created_at
- updated_at
```

## API Integrations

### Sleeper API
- **Endpoints**:
  - `/league/{league_id}` - League information
  - `/league/{league_id}/users` - League members
  - `/league/{league_id}/matchups/{week}` - Weekly matchups
  - `/league/{league_id}/transactions/{week}` - Transactions
  - `/players` - Player database
- **Rate Limiting**: Implement caching and respectful API usage
- **Data Sync**: Background jobs for regular data updates

### ChatGPT API
- **Model**: GPT-4 or GPT-3.5-turbo
- **Context Building**:
  - League history and context
  - Current week's scores and matchups
  - Player performance data
  - Previous press conference context
- **Prompt Engineering**:
  - Coach persona with entertainment value
  - 45-second response length target
  - Appropriate tone (fun, competitive, dramatic)

### PlayHT API
- **Voice Cloning**:
  - Upload audio samples
  - Create voice clones
  - Manage clone lifecycle
- **Text-to-Speech**:
  - Generate questions with standard voices
  - Generate responses with cloned voices
  - Manage audio file downloads

## File Storage Strategy

### AWS S3 Buckets
- **Structure**:
  ```
  /leagues/{league_id}/
    /voices/
      /originals/{user_id}/sample.wav
      /processed/{user_id}/sample_processed.wav
      /clones/{voice_clone_id}/
    /press_conferences/{press_conference_id}/
      /questions/{question_id}.mp3
      /responses/{response_id}.mp3
      /complete/{press_conference_id}_complete.mp3
  ```
- **Security**: Signed URLs for temporary access
- **Cleanup**: Background jobs for old file management

### Audio Processing Pipeline
- **Upload Processing**: FFmpeg converts uploaded files to consistent format (WAV, 44.1kHz, mono)
- **Voice Recording**: Browser recordings processed and optimized for PlayHT compatibility
- **Press Conference Assembly**: FFmpeg stitches questions and responses with appropriate pauses
- **Format Optimization**: Multiple formats generated (MP3 for web, high-quality for archival)
- **Background Processing**: All audio processing handled via background jobs to prevent timeouts

## Security & Privacy

### Access Control
- League-specific data isolation
- Role-based permissions (owner vs manager)
- 404 responses for unauthorized access
- Secure file upload tokens

### Data Protection
- Voice samples encrypted at rest
- Secure API key management via ENV variables
- HTTPS everywhere
- Session security with Rails defaults

### Privacy Considerations
- Voice sample consent and management
- Data retention policies
- User data deletion capabilities

## User Experience

### League Owner Workflows
1. **Setup**: Connect Sleeper league, invite managers
2. **Voice Management**: Upload voices or send secure links
3. **Press Conference Creation**: Select week, customize questions
4. **Content Management**: View, share, and archive conferences

### Team Manager Workflows
1. **Voice Recording**: Browser-based voice recording or file upload via secure link
2. **Voice Preview**: Listen to recorded samples before submission
3. **Content Viewing**: Access own press conferences and league content with in-browser playback
4. **Profile Management**: Update personal information

### Design System
- **Color Palette**: Sleeper-inspired colors (#1A202C, #2D3748, #4A5568, #00D9FF, #FF6B35)
- **Components**: Tailwind CSS utility classes with custom audio components
- **Mobile-First**: Optimized for mobile devices with touch-friendly controls
- **Audio UI**: Custom audio players, recording interfaces, and waveform visualizations
- **Progressive Web App**: Installable on mobile devices
- **Accessibility**: WCAG 2.1 AA compliance with screen reader support for audio content

## Mobile & Browser Compatibility

### Mobile-First Features
- **Touch-Optimized**: Large touch targets for recording and playback controls
- **Responsive Audio**: Adaptive audio quality based on connection speed
- **Offline Capability**: Service worker for offline press conference playback
- **Native Feel**: iOS/Android styled components using Tailwind

### Browser Audio Support
- **MediaRecorder API**: Chrome, Firefox, Safari support for voice recording
- **Web Audio API**: Cross-browser audio processing and visualization
- **Fallback Support**: File upload option for unsupported browsers
- **Format Compatibility**: Multiple audio formats (MP3, WAV, OGG) for broad support

### Performance Optimizations
- **Lazy Loading**: Audio files loaded on-demand
- **Compression**: Optimized audio compression for mobile data usage
- **Caching**: Browser caching for frequently played press conferences
- **Progressive Enhancement**: Core functionality works without JavaScript

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Rails 8 application setup
- [ ] Code quality tools setup (RuboCop with Airbnb config, Brakeman, SimpleCov)
- [ ] Database schema implementation
- [ ] User authentication (Devise)
- [ ] Basic league management
- [ ] Sleeper API integration
- [ ] Testing framework setup (RSpec, FactoryBot)

### Phase 2: Voice System (Weeks 3-4)
- [ ] File upload system (S3 integration)
- [ ] FFmpeg integration for audio processing
- [ ] Browser-based voice recording (MediaRecorder API)
- [ ] Audio format conversion and optimization
- [ ] PlayHT API integration
- [ ] Voice cloning workflow
- [ ] Secure upload link generation
- [ ] Voice management interface with audio preview

### Phase 3: Press Conference Engine (Weeks 5-6)
- [ ] ChatGPT API integration
- [ ] Context building system
- [ ] Press conference generation workflow
- [ ] Audio stitching with FFmpeg (questions + responses + pauses)
- [ ] Complete press conference assembly pipeline
- [ ] Background job system for audio processing

### Phase 4: Frontend & UX (Weeks 7-8)
- [ ] Stimulus controllers for audio recording and playback
- [ ] Hotwire implementations for real-time updates
- [ ] Mobile-first Tailwind styling
- [ ] Touch-friendly responsive design
- [ ] Custom audio player components with waveform visualization
- [ ] Progressive Web App configuration
- [ ] Cross-browser audio compatibility testing

### Phase 5: Polish & Deploy (Weeks 9-10)
- [ ] Error handling and logging
- [ ] Performance optimization
- [ ] Security audit (Brakeman scan)
- [ ] Code quality review (RuboCop, Reek analysis)
- [ ] Heroku deployment
- [ ] Production monitoring

## Testing Strategy

### Unit Tests (RSpec)
- Model validations and associations
- Service object functionality
- API integration classes
- Background job processing

### Integration Tests
- User authentication flows
- File upload processes
- API integration workflows
- Press conference generation

### System Tests
- End-to-end user journeys
- File upload and processing
- Audio generation and playback
- Cross-browser compatibility

### Test Data (FactoryBot)
- User and league factories
- Mock API responses
- Sample audio files for testing
- Press conference scenarios

## Code Standards & Style Guide

### Ruby Style Guide
- **Standard**: [Airbnb Ruby Style Guide](https://github.com/airbnb/ruby)
- **Linting**: RuboCop with Airbnb configuration (`rubocop-airbnb` gem)
- **Key Guidelines**:
  - 2-space soft tabs for indentation
  - Prefer symbols over strings for hash keys
  - Use `map` over `collect`, `detect` over `find`
  - String interpolation over concatenation
  - Trailing commas in multi-line arrays and hashes
  - Named groups in regular expressions
  - Lambda syntax for ActiveRecord scopes

### Code Quality Tools
- **RuboCop**: Static code analyzer with Airbnb rules
- **Brakeman**: Security vulnerability scanner
- **SimpleCov**: Code coverage reporting
- **Reek**: Code smell detector

## Configuration Management

### Environment Variables
```bash
# Database
DATABASE_URL=

# APIs
OPENAI_API_KEY=
PLAYHT_API_KEY=
PLAYHT_USER_ID=
SLEEPER_API_BASE_URL=

# AWS
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
AWS_S3_BUCKET=

# Application
SECRET_KEY_BASE=
RAILS_ENV=
```

### Key Gems & Dependencies
```ruby
# Code Quality & Standards
gem 'rubocop-airbnb', require: false
gem 'brakeman', require: false
gem 'reek', require: false
gem 'simplecov', require: false

# Core Application
gem 'rails', '~> 8.0'
gem 'pg', '~> 1.1'
gem 'devise'
gem 'image_processing', '~> 1.2'

# Background Jobs & Caching
gem 'sidekiq'
gem 'redis', '~> 4.0'

# API Integrations
gem 'httparty'
gem 'aws-sdk-s3'

# Testing
gem 'rspec-rails'
gem 'factory_bot_rails'
gem 'capybara'
gem 'selenium-webdriver'
```

### Deployment Configuration
- Heroku buildpacks for Rails and FFmpeg
- PostgreSQL addon
- Redis addon (for background jobs)
- S3 bucket configuration
- Environment variable management
- FFmpeg binary configuration for Heroku

## Performance Considerations

### Caching Strategy
- Redis for session storage
- API response caching
- Fragment caching for league data
- CDN for static assets

### Background Processing
- Sidekiq for background jobs
- Voice cloning processing
- Audio generation queues
- Data sync jobs

### Monitoring
- Application performance monitoring
- Error tracking (Bugsnag/Sentry)
- API usage monitoring
- File storage usage tracking

## Future Enhancements

### Potential Features
- Multi-league management
- Press conference scheduling
- Social sharing capabilities
- Mobile app development
- Advanced analytics and reporting
- Custom question templates
- League-wide tournaments

### Scalability Considerations
- Database sharding by league
- CDN for global audio delivery
- Microservice architecture
- Advanced caching strategies

## Success Metrics

### Technical Metrics
- Voice cloning success rate (>95%)
- Audio generation time (<2 minutes)
- Application uptime (>99.5%)
- API response times (<500ms)

### User Engagement
- Press conference creation rate
- Voice sample upload completion
- User retention and satisfaction
- Feature adoption rates

---

*This planning document will be updated as requirements evolve and technical decisions are finalized during development.* 