# Voice Sample Upload Feature Plan

## Overview
Implementation plan for allowing users to upload voice samples via file upload or browser-based recording, with shareable links for third-party submissions.

## Current Architecture Analysis

### Existing Components
- **VoiceClone Model** (`app/models/voice_clone.rb`) - Links to league_membership with PlayHT integration
- **Database Schema** - `voice_clones` table with status tracking and upload tokens
- **Routes** - Nested voice_clones routes and public voice_uploads routes already defined
- **Press Conference Integration** - Uses voice clones for AI-generated audio responses

### Missing Components
- VoiceClones and VoiceUploads controllers
- File upload/recording UI
- Audio processing pipeline
- File storage implementation

## Phase 1: League Owner Voice Upload

### Database Schema Updates
No schema changes needed - current `voice_clones` table supports the feature:
```sql
-- Existing table already has:
-- original_audio_url (for uploaded files)
-- upload_token (for secure access)
-- status (pending, processing, ready, failed)
```

### File Storage Strategy
**Recommendation: Rails Active Storage**
- Built-in Rails solution with local/cloud flexibility
- Seamless integration with existing codebase
- Supports direct uploads to cloud storage
- Automatic file validation and processing
- App is hosted on Heroku so we'll need to use S3 for persistant file uploads

### Implementation Components

#### 1. VoiceClonesController (`app/controllers/voice_clones_controller.rb`)
```ruby
class VoiceClonesController < ApplicationController
  # Nested under league_memberships
  # Actions: show, new, create, edit, update, destroy
  # Handles file uploads via Active Storage
end
```

#### 2. Audio Recording Interface
**Technology: MediaRecorder API**
- Native browser support (Chrome, Firefox, Safari)
- No external dependencies
- Real-time audio visualization
- WebM/MP4 format support

**UI Components:**
- Record button with visual feedback
- Audio playback preview
- Re-record functionality
- File upload alternative

#### 3. File Validation Pipeline
**Supported Formats:** MP3, WAV, M4A, WebM
**Validation Rules:**
- File size: 1MB - 50MB
- Duration: 30 seconds - 10 minutes
- Sample rate: 16kHz minimum
- Channels: Mono/Stereo

#### 4. Processing Workflow
```ruby
class VoiceProcessingJob < ApplicationJob
  def perform(voice_clone_id)
    # 1. Validate audio file
    # 2. Convert to optimal format if needed
    # 3. Upload to PlayHT
    # 4. Update voice_clone status
    # 5. Send notification email
  end
end
```

## Phase 2: Shareable Upload Links

### Database Schema Addition
Add new table for shareable links:
```ruby
create_table :voice_upload_links do |t|
  t.references :voice_clone, null: false, foreign_key: true
  t.string :public_token, null: false      # UUID for public access
  t.string :title                          # "Upload voice for John's character"
  t.text :instructions                     # Custom instructions for uploader
  t.datetime :expires_at                   # Optional expiration
  t.boolean :active, default: true         # Enable/disable link
  t.integer :max_uploads, default: 1       # Limit submissions per link
  t.integer :upload_count, default: 0      # Track usage
  t.timestamps
end
```

### Implementation Components

#### 1. VoiceUploadsController (`app/controllers/voice_uploads_controller.rb`)
```ruby
class VoiceUploadsController < ApplicationController
  # Public controller - no authentication required
  # Actions: show (upload form), create (process upload)
  # Access via public_token parameter
end
```

#### 2. Link Management Interface
**For League Owners:**
- Generate shareable links
- Customize upload instructions
- Set expiration dates
- Monitor upload status
- Regenerate/deactivate links

#### 3. Public Upload Interface
**Features:**
- Clean, simple upload form
- Progress indicators
- Success/error feedback
- Mobile-responsive design
- No account registration required

### Security Measures

#### Token Security
- **Upload Token**: 32-byte secure random (existing)
- **Public Token**: UUID v4 for shareable links
- **No Sequential IDs**: Prevents URL enumeration
- **Expiration**: Optional time-based expiration
- **Rate Limiting**: Prevent abuse

#### File Security
- **Virus Scanning**: Integrate with ClamAV or similar
- **Content Validation**: Verify actual audio content
- **Size Limits**: Prevent storage abuse
- **Format Restriction**: Only allow audio files

#### Privacy Protection
- **No Metadata Storage**: Strip EXIF/metadata
- **Secure URLs**: Use signed URLs for file access
- **Access Logging**: Track all upload attempts
- **GDPR Compliance**: Clear data retention policies

## Technical Implementation Plan

### Phase 1 Tasks (League Owner Upload)
1. **Setup Active Storage**
   - Configure storage service (local → cloud migration path)
   - Add audio file validation
   - Create attachment associations

2. **Build VoiceClonesController**
   - Implement CRUD operations
   - Handle file uploads
   - Integrate with existing authentication

3. **Create Upload UI**
   - File upload form with drag-and-drop
   - Audio recording interface
   - Progress indicators and validation feedback

4. **Implement Processing Pipeline**
   - Background job for audio processing
   - PlayHT API integration (build in a way that can be extracted to a gem using the same patterns as the sleeper_ff gem)
   - Status updates and notifications

5. **Add Audio Player**
   - Preview uploaded samples
   - Playback controls
   - Waveform visualization (optional)

### Phase 2 Tasks (Shareable Links)
1. **Database Migration**
   - Create voice_upload_links table
   - Add necessary indexes
   - Update model associations

2. **Build VoiceUploadsController**
   - Public upload form
   - Token-based access control
   - Upload processing

3. **Link Management Interface**
   - Generate/manage shareable links
   - Customize upload instructions
   - Monitor upload activity

4. **Security Implementation**
   - Rate limiting
   - File validation
   - Access logging

### Integration Points

#### PlayHT API Integration
- **Existing**: `playht_voice_id` field in voice_clones
- **New**: Audio file upload to PlayHT
- **Process**: File → PlayHT → Voice ID → Update status

#### Background Job Processing
- **Queue**: Solid Queue (already configured)
- **Jobs**: Audio processing, PlayHT upload, status updates
- **Monitoring**: Job status tracking in admin interface

#### Email Notifications
- **Upload Success**: Notify league owner when voice is ready
- **Processing Status**: Update on voice cloning progress
- **Link Activity**: Notify when shared link is used

## Testing Strategy

### Unit Tests
- Model validations and associations
- File upload and processing logic
- Token generation and validation
- Background job processing

### Integration Tests
- File upload workflows
- Audio recording functionality
- PlayHT API integration
- Email notifications

### System Tests
- End-to-end upload process
- Browser recording functionality
- Mobile responsiveness
- Error handling scenarios

## Performance Considerations

### File Storage
- **CDN Integration**: Serve audio files via CDN
- **Compression**: Optimize audio files for web delivery
- **Lazy Loading**: Load audio players on demand

### Background Processing
- **Job Prioritization**: High priority for voice processing
- **Retry Logic**: Robust error handling for API failures
- **Monitoring**: Track job performance and failures

### Database Optimization
- **Indexes**: Optimize queries for upload links
- **Cleanup**: Regular cleanup of expired/unused uploads
- **Monitoring**: Track storage usage and performance

## Deployment Considerations

### Environment Variables
```bash
# File storage
ACTIVE_STORAGE_SERVICE=local  # or amazon, google, azure
AWS_ACCESS_KEY_ID=<key>       # if using AWS
AWS_SECRET_ACCESS_KEY=<secret>

# PlayHT Integration
PLAYHT_API_KEY=<api_key>
PLAYHT_USER_ID=<user_id>

# Security
VOICE_UPLOAD_MAX_SIZE=50MB
VOICE_UPLOAD_RATE_LIMIT=5/hour
```

### Infrastructure Requirements
- **File Storage**: 1GB+ per 1000 users (estimated)
- **Processing Power**: Background job workers for audio processing
- **CDN**: For efficient audio file delivery
- **Monitoring**: File storage usage and processing metrics

## Success Metrics

### Phase 1 Metrics
- Voice upload completion rate
- Processing success rate
- User satisfaction with upload experience
- Audio quality of processed files

### Phase 2 Metrics
- Shareable link usage rate
- Third-party upload success rate
- Link sharing patterns
- Security incident frequency

## Risk Mitigation

### Technical Risks
- **Audio Quality**: Test with various input formats
- **Processing Failures**: Robust error handling and retry logic
- **Storage Costs**: Monitor and optimize file sizes

### Security Risks
- **Malicious Uploads**: Comprehensive file validation
- **Privacy Concerns**: Clear data handling policies
- **Abuse Prevention**: Rate limiting and monitoring

### User Experience Risks
- **Browser Compatibility**: Test across all major browsers
- **Mobile Experience**: Responsive design and touch optimization
- **Error Handling**: Clear error messages and recovery paths

This plan provides a comprehensive roadmap for implementing voice sample uploads with both direct owner access and shareable link functionality, building on the existing voice cloning architecture while maintaining security and performance standards.