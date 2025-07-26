# League Event Scheduling - Technical Architecture Plan

## 1. Data Model Design

### Database Schema

```sql
-- Core scheduling poll table (generic for any event type)
create_table "scheduling_polls", force: :cascade do |t|
  t.bigint "league_id", null: false
  t.bigint "created_by_id", null: false
  t.string "public_token", null: false
  t.string "event_type", null: false # draft, playoffs, trade_deadline, weekly_matchup, etc.
  t.string "title", null: false
  t.text "description"
  t.integer "status", default: 0, null: false # enum: active, closed, cancelled
  t.datetime "closes_at"
  t.jsonb "settings", default: {} # event-specific settings
  t.jsonb "event_metadata", default: {} # event-specific data (week_number, trade_parties, etc.)
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  
  t.index ["league_id"], name: "index_scheduling_polls_on_league_id"
  t.index ["created_by_id"], name: "index_scheduling_polls_on_created_by_id"
  t.index ["public_token"], name: "index_scheduling_polls_on_public_token", unique: true
  t.index ["status"], name: "index_scheduling_polls_on_status"
  t.index ["event_type"], name: "index_scheduling_polls_on_event_type"
  t.index ["league_id", "event_type"], name: "index_scheduling_polls_on_league_and_type"
end

-- Time slot options for each poll
create_table "event_time_slots", force: :cascade do |t|
  t.bigint "scheduling_poll_id", null: false
  t.datetime "starts_at", null: false
  t.integer "duration_minutes", default: 60, null: false # varies by event type
  t.jsonb "slot_metadata", default: {} # event-specific slot data
  t.integer "order_index", default: 0
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  
  t.index ["scheduling_poll_id"], name: "index_event_time_slots_on_poll_id"
  t.index ["starts_at"], name: "index_event_time_slots_on_starts_at"
end

-- Responses from league members
create_table "scheduling_responses", force: :cascade do |t|
  t.bigint "scheduling_poll_id", null: false
  t.string "respondent_name", null: false
  t.string "respondent_identifier", null: false # unique per poll for updating responses
  t.string "ip_address" # for rate limiting
  t.jsonb "metadata", default: {} # user agent, additional response data
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  
  t.index ["scheduling_poll_id", "respondent_identifier"], 
    name: "index_scheduling_responses_on_poll_and_identifier", unique: true
  t.index ["scheduling_poll_id"], name: "index_scheduling_responses_on_poll_id"
  t.index ["ip_address"], name: "index_scheduling_responses_on_ip_address"
end

-- Individual availability for each time slot
create_table "slot_availabilities", force: :cascade do |t|
  t.bigint "scheduling_response_id", null: false
  t.bigint "event_time_slot_id", null: false
  t.integer "availability", null: false # enum: unavailable(0), maybe(1), available(2)
  t.jsonb "preference_data", default: {} # event-specific preferences
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  
  t.index ["scheduling_response_id", "event_time_slot_id"], 
    name: "index_slot_availability_unique", unique: true
  t.index ["event_time_slot_id"], name: "index_slot_availability_on_slot"
end
```

### Model Relationships and Key Methods

```ruby
# app/models/scheduling_poll.rb
class SchedulingPoll < ApplicationRecord
  belongs_to :league
  belongs_to :created_by, class_name: 'User'
  
  has_many :event_time_slots, -> { order(:order_index, :starts_at) }, dependent: :destroy
  has_many :scheduling_responses, dependent: :destroy
  
  enum status: { active: 0, closed: 1, cancelled: 2 }
  
  # Event types that can be extended
  EVENT_TYPES = {
    draft: 'Draft',
    playoffs: 'Playoffs',
    trade_deadline: 'Trade Deadline',
    weekly_matchup: 'Weekly Matchup',
    trophy_ceremony: 'Trophy Ceremony',
    league_meeting: 'League Meeting'
  }.freeze
  
  before_create :generate_public_token
  before_validation :set_default_title
  
  validates :title, presence: true, length: { maximum: 100 }
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES.keys.map(&:to_s) }
  validates :event_time_slots, presence: true
  
  # Scopes for different event types
  scope :drafts, -> { where(event_type: 'draft') }
  scope :playoffs, -> { where(event_type: 'playoffs') }
  scope :active_for_league, ->(league) { where(league: league, status: :active) }
  
  # Key methods:
  # - response_count
  # - response_rate (percentage of league members who responded)
  # - optimal_slots (returns slots with highest availability)
  # - availability_matrix (for visualization)
  # - close! (transitions status and prevents new responses)
  # - event_specific_defaults (returns defaults based on event_type)
  
  def default_duration_minutes
    case event_type
    when 'draft' then 180
    when 'playoffs' then 120
    when 'trade_deadline' then 30
    when 'weekly_matchup' then 60
    else 60
    end
  end
  
  private
  
  def set_default_title
    self.title ||= "#{EVENT_TYPES[event_type.to_sym]} Scheduling Poll" if event_type.present?
  end
end

# app/models/event_time_slot.rb
class EventTimeSlot < ApplicationRecord
  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy
  
  validates :starts_at, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  
  delegate :event_type, to: :scheduling_poll
  
  # Key methods:
  # - ends_at
  # - availability_summary (counts by type)
  # - availability_score (weighted score for optimization)
  # - formatted_time (respects league timezone)
  # - display_label (event-specific formatting)
  
  def display_label
    case scheduling_poll.event_type
    when 'weekly_matchup'
      "#{formatted_time} - Quick sync"
    when 'draft'
      "#{formatted_time} - #{duration_minutes/60}hr draft window"
    else
      "#{formatted_time} - #{duration_minutes}min"
    end
  end
end

# app/models/scheduling_response.rb
class SchedulingResponse < ApplicationRecord
  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy
  
  validates :respondent_name, presence: true, length: { maximum: 50 }
  validates :respondent_identifier, presence: true, uniqueness: { scope: :scheduling_poll_id }
  
  accepts_nested_attributes_for :slot_availabilities
  
  # Key methods:
  # - update_availability(slot_availabilities_params)
  # - available_for?(event_time_slot)
  # - preference_level_for(event_time_slot)
end

# app/models/slot_availability.rb
class SlotAvailability < ApplicationRecord
  belongs_to :scheduling_response
  belongs_to :event_time_slot
  
  enum availability: { unavailable: 0, maybe: 1, available: 2 }
  
  validates :availability, presence: true
  
  # Can store event-specific preferences in preference_data
  # e.g., for trades: { "preferred_partner": "user_123" }
end
```

## 2. System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (Browser)                         │
├─────────────────────────┬────────────────────┬──────────────────┤
│   Commissioner View     │   Public Response   │   Results View   │
│   (Authenticated)       │   Form (No Auth)    │  (Authenticated) │
├─────────────────────────┴────────────────────┴──────────────────┤
│                     Stimulus Controllers                          │
│  - SchedulingPollController                                      │
│  - TimeSlotController                                            │
│  - AvailabilityGridController                                   │
│  - EventTypeController (dynamic UI per event)                    │
└─────────────────────────┬────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                    Rails Controllers                              │
├─────────────────────────┬────────────────────┬──────────────────┤
│ SchedulingPolls         │ PublicScheduling   │ PollResults      │
│ Controller              │ Controller          │ Controller       │
└─────────────────────────┴────────────────────┴──────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                   Domain Objects (POROs)                          │
├─────────────────────────┬────────────────────┬──────────────────┤
│ PollCreator            │ ResponseRecorder    │ AvailabilityCalc │
│ EventPollFactory       │ DuplicateResolver  │ OptimalTimeFinder│
│ EventTypeRegistry      │ EventValidator      │ PreferenceEngine │
└─────────────────────────┴────────────────────┴──────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                    ActiveRecord Models                            │
│      (SchedulingPoll, EventTimeSlot, SlotAvailability)          │
└─────────────────────────┬────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                       PostgreSQL                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Request Flow Patterns

1. **Poll Creation Flow** (Authenticated)
   - Commissioner → LeaguesController#dashboard → "Schedule Event" dropdown
   - → Select event type (Draft, Playoffs, Trade Deadline, etc.)
   - → SchedulingPollsController#new → Event-specific form with Stimulus enhancements
   - → SchedulingPollsController#create → EventPollFactory PORO
   - → Redirect to poll management page with shareable link

2. **Public Response Flow** (No Auth Required)
   - League member clicks link → PublicSchedulingController#show
   - → Renders response form with event-appropriate time slots
   - → PublicSchedulingController#update → ResponseRecorder PORO
   - → Optimistic locking for concurrent updates
   - → Success page with ability to update response

3. **Results Viewing Flow** (Authenticated)
   - Commissioner → SchedulingPollsController#show
   - → AvailabilityCalculator generates matrix
   - → OptimalTimeFinder suggests best slots (event-aware logic)
   - → Real-time updates via Turbo Streams

## 3. Security Architecture

### Authentication & Authorization

```ruby
# app/controllers/scheduling_polls_controller.rb
class SchedulingPollsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league
  before_action :authorize_poll_creation!, only: [:new, :create]
  before_action :authorize_poll_management!, only: [:edit, :update, :destroy, :close]
  
  private
  
  def authorize_poll_creation!
    # Different event types may have different authorization rules
    case params[:event_type]
    when 'draft', 'playoffs', 'league_meeting'
      authorize_commissioner!
    when 'trade_deadline'
      authorize_trade_participant!
    when 'weekly_matchup'
      authorize_matchup_participant!
    else
      authorize_commissioner!
    end
  end
  
  def authorize_commissioner!
    redirect_to leagues_path unless @league.owner == current_user
  end
end

# app/controllers/public_scheduling_controller.rb
class PublicSchedulingController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_poll_by_token
  before_action :check_poll_active
  before_action :apply_rate_limiting
  
  private
  
  def apply_rate_limiting
    RateLimiter.check!(
      key: "scheduling_response:#{request.remote_ip}",
      limit: 10,
      period: 1.hour
    )
  end
end
```

### Security Measures

1. **Public Token Generation**
   ```ruby
   # app/models/concerns/public_token_generator.rb
   module PublicTokenGenerator
     extend ActiveSupport::Concern
     
     included do
       before_create :generate_public_token
     end
     
     private
     
     def generate_public_token
       loop do
         self.public_token = SecureRandom.urlsafe_base64(8)
         break unless self.class.exists?(public_token: public_token)
       end
     end
   end
   ```

2. **Rate Limiting Implementation**
   ```ruby
   # app/models/rate_limiter.rb
   class RateLimiter
     def self.check!(key:, limit:, period:)
       count = Rails.cache.increment("rate_limit:#{key}", 1, expires_in: period)
       raise TooManyRequestsError if count > limit
     end
   end
   ```

3. **Input Validation & Sanitization**
   - Strong parameters for all inputs
   - Name validation to prevent XSS
   - Response identifier hashing for privacy
   - IP address logging for abuse detection

4. **CSRF Protection for Public Forms**
   ```ruby
   # Alternative approach without CSRF tokens
   # Use honeypot fields and timestamp validation
   class SpamProtection
     def self.valid_submission?(params, session)
       return false if params[:honeypot].present?
       return false if Time.current - session[:form_loaded_at] < 2.seconds
       true
     end
   end
   ```

## 4. API Design

### RESTful Routes

```ruby
# config/routes.rb
resources :leagues do
  resources :scheduling_polls do
    member do
      patch :close
      patch :reopen
      get :results
      get :export # CSV/Calendar export
    end
    
    resources :event_time_slots, only: [:create, :update, :destroy]
  end
end

# Public routes (no authentication)
get '/schedule/:token', to: 'public_scheduling#show', as: :public_scheduling
post '/schedule/:token', to: 'public_scheduling#create'
patch '/schedule/:token', to: 'public_scheduling#update'

# Event-specific routes (future enhancement)
namespace :scheduling do
  resources :drafts, only: [:new]
  resources :playoffs, only: [:new]
  resources :trades, only: [:new]
end
```

### Controller Actions

```ruby
# Authenticated endpoints
POST   /leagues/:league_id/scheduling_polls?event_type=draft
GET    /leagues/:league_id/scheduling_polls/:id
PATCH  /leagues/:league_id/scheduling_polls/:id/close
GET    /leagues/:league_id/scheduling_polls/:id/results
GET    /leagues/:league_id/scheduling_polls/:id/export.csv

# Public endpoints
GET    /schedule/:token
POST   /schedule/:token (create response)
PATCH  /schedule/:token (update response)

# Event-specific creation (future)
GET    /scheduling/drafts/new?league_id=:id
GET    /scheduling/trades/new?league_id=:id&participants[]=:id1&participants[]=:id2
```

### JSON API Responses (for Turbo/Stimulus)

```ruby
# GET /leagues/:league_id/scheduling_polls/:id/results.json
{
  "poll": {
    "id": 1,
    "event_type": "draft",
    "title": "2024 Draft Scheduling",
    "response_count": 8,
    "response_rate": 80,
    "status": "active",
    "event_metadata": {
      "season": "2024",
      "round": 1
    }
  },
  "time_slots": [
    {
      "id": 1,
      "starts_at": "2024-08-15T19:00:00Z",
      "duration_minutes": 180,
      "availability_counts": {
        "available": 6,
        "maybe": 1,
        "unavailable": 1
      },
      "score": 85,
      "slot_metadata": {
        "venue": "online",
        "platform": "sleeper"
      }
    }
  ],
  "responses": [
    {
      "name": "John Doe",
      "availabilities": {
        "1": "available",
        "2": "maybe"
      },
      "preferences": {
        "1": { "platform_preference": "sleeper" }
      }
    }
  ],
  "optimal_recommendation": {
    "slot_id": 1,
    "reasoning": "Highest availability with 6 confirmed attendees"
  }
}
```

## 5. Performance Considerations

### Database Optimization

1. **Indexes**
   ```sql
   -- Composite indexes for common queries
   add_index :slot_availabilities, 
     [:event_time_slot_id, :availability], 
     name: "index_slot_availability_counts"
   
   -- Covering index for response lookups
   add_index :scheduling_responses,
     [:scheduling_poll_id, :created_at],
     name: "index_responses_for_listing"
   
   -- Event type specific queries
   add_index :scheduling_polls,
     [:league_id, :event_type, :status],
     name: "index_polls_by_league_type_status"
   ```

2. **Query Optimization**
   ```ruby
   # Eager load all data for results page
   class SchedulingPoll < ApplicationRecord
     scope :with_full_results, -> {
       includes(
         event_time_slots: {
           slot_availabilities: :scheduling_response
         }
       )
     }
     
     # Event-specific scopes for performance
     scope :active_drafts, -> { where(event_type: 'draft', status: :active) }
     scope :upcoming_events, -> { joins(:event_time_slots).where('event_time_slots.starts_at > ?', Time.current).distinct }
   end
   ```

3. **Database Views for Complex Queries**
   ```sql
   CREATE MATERIALIZED VIEW event_availability_summary AS
   SELECT 
     ets.id as time_slot_id,
     ets.scheduling_poll_id,
     sp.event_type,
     COUNT(CASE WHEN sa.availability = 2 THEN 1 END) as available_count,
     COUNT(CASE WHEN sa.availability = 1 THEN 1 END) as maybe_count,
     COUNT(CASE WHEN sa.availability = 0 THEN 1 END) as unavailable_count,
     -- Event-specific aggregations
     CASE 
       WHEN sp.event_type = 'draft' THEN COUNT(CASE WHEN sa.availability = 2 THEN 1 END) * 2.0
       WHEN sp.event_type = 'trade_deadline' THEN COUNT(CASE WHEN sa.availability > 0 THEN 1 END) * 1.5
       ELSE COUNT(CASE WHEN sa.availability = 2 THEN 1 END) * 1.0
     END as weighted_score
   FROM event_time_slots ets
   JOIN scheduling_polls sp ON ets.scheduling_poll_id = sp.id
   LEFT JOIN slot_availabilities sa ON ets.id = sa.event_time_slot_id
   GROUP BY ets.id, sp.event_type;
   
   -- Refresh after updates
   REFRESH MATERIALIZED VIEW CONCURRENTLY event_availability_summary;
   ```

### Caching Strategy

1. **Fragment Caching with Event Context**
   ```erb
   <!-- app/views/scheduling_polls/_results_grid.html.erb -->
   <% cache [@poll, @poll.event_type, @poll.updated_at, 'results-grid'] do %>
     <%= render "availability_grids/#{@poll.event_type}", poll: @poll %>
   <% end %>
   ```

2. **Russian Doll Caching**
   ```erb
   <% cache [@poll, @poll.event_type] do %>
     <% @poll.event_time_slots.each do |slot| %>
       <% cache [slot, @poll.event_type] do %>
         <%= render "time_slots/#{@poll.event_type}_slot", slot: slot %>
       <% end %>
     <% end %>
   <% end %>
   ```

3. **Response Caching for Public Pages**
   ```ruby
   class PublicSchedulingController < ApplicationController
     def show
       expires_in 5.minutes, public: true
       fresh_when @poll
     end
   end
   ```

### Concurrent Access Handling

1. **Optimistic Locking for Responses**
   ```ruby
   class ResponseRecorder
     def record(poll, params)
       response = find_or_initialize_response(poll, params)
       
       ActiveRecord::Base.transaction do
         response.lock! # Pessimistic lock for this transaction
         response.update!(response_params)
         update_availabilities(response, params[:availabilities])
       end
     rescue ActiveRecord::StaleObjectError
       retry
     end
   end
   ```

2. **Connection Pooling Configuration**
   ```yaml
   # config/database.yml
   production:
     pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 20 } %>
     checkout_timeout: 10
     reaping_frequency: 10
   ```

## 6. Technology Choices

### Gems and Libraries

1. **Core Dependencies** (already in stack)
   - Rails 8.0.2
   - PostgreSQL adapter
   - Devise (authentication)
   - Solid Queue (background jobs)
   - Turbo & Stimulus

2. **Additional Gems for This Feature**
   ```ruby
   # Gemfile additions
   
   # For timezone handling
   gem 'tzinfo-data'
   
   # For better date/time parsing in forms
   gem 'chronic' # Natural language date parsing
   
   # For IP-based rate limiting
   gem 'rack-attack'
   
   # For analytics/monitoring
   gem 'ahoy_matey' # Track poll creation and response rates
   ```

### Frontend Technologies

1. **Stimulus Controllers**
   ```javascript
   // app/javascript/controllers/scheduling_poll_controller.js
   // - Handle dynamic time slot addition/removal
   // - Client-side validation
   // - Preview mode
   
   // app/javascript/controllers/availability_grid_controller.js
   // - Interactive grid for selecting availability
   // - Bulk selection tools
   // - Visual feedback
   
   // app/javascript/controllers/time_zone_controller.js
   // - Auto-detect user timezone
   // - Convert times for display
   ```

2. **Turbo Streams for Real-time Updates**
   ```ruby
   # app/views/draft_scheduling_responses/create.turbo_stream.erb
   <%= turbo_stream.update "response_count", 
       @poll.draft_scheduling_responses.count %>
   <%= turbo_stream.replace "availability_grid",
       partial: "draft_scheduling_polls/availability_grid",
       locals: { poll: @poll } %>
   ```

### Design Patterns

1. **Domain Objects (POROs)**
   ```ruby
   # app/models/event_poll_factory.rb
   class EventPollFactory
     def self.build(league, user, params)
       event_type = params[:event_type]
       builder = "#{event_type.camelize}PollBuilder".constantize.new(league, user, params)
       builder.build
     rescue NameError
       GenericPollBuilder.new(league, user, params).build
     end
   end
   
   # app/models/poll_builders/draft_poll_builder.rb
   class DraftPollBuilder < GenericPollBuilder
     def build
       super.tap do |poll|
         poll.settings[:require_all_responses] = true
         poll.settings[:default_duration] = 180
         poll.event_metadata[:season] = current_season
       end
     end
   end
   
   # app/models/poll_builders/trade_poll_builder.rb
   class TradePollBuilder < GenericPollBuilder
     def build
       super.tap do |poll|
         poll.settings[:max_responses] = 2
         poll.settings[:default_duration] = 30
         poll.event_metadata[:trade_parties] = @params[:participants]
       end
     end
   end
   
   # app/models/optimal_time_finder.rb
   class OptimalTimeFinder
     def initialize(poll)
       @poll = poll
       @strategy = strategy_for_event_type
     end
     
     def find_best_slots(limit: 3)
       @strategy.find_optimal_slots(@poll, limit)
     end
     
     private
     
     def strategy_for_event_type
       case @poll.event_type
       when 'draft'
         DraftOptimizationStrategy.new
       when 'trade_deadline'
         TradeOptimizationStrategy.new
       else
         DefaultOptimizationStrategy.new
       end
     end
   end
   ```

2. **Value Objects**
   ```ruby
   # app/models/time_slot_availability.rb
   class TimeSlotAvailability
     attr_reader :available, :maybe, :unavailable, :preferences
     
     def initialize(slot)
       @slot = slot
       @event_type = slot.scheduling_poll.event_type
       calculate_counts
       extract_preferences
     end
     
     def score
       base_score * event_weight_multiplier
     end
     
     private
     
     def base_score
       (available * 2 + maybe * 1) / total_responses.to_f * 100
     end
     
     def event_weight_multiplier
       case @event_type
       when 'draft' then 1.5  # Prioritize full availability for drafts
       when 'trade_deadline' then 1.2  # Some flexibility for trades
       else 1.0
       end
     end
   end
   
   # app/models/event_type_registry.rb
   class EventTypeRegistry
     REGISTRY = {
       draft: {
         name: 'Draft',
         default_duration: 180,
         requires_all: true,
         icon: 'calendar',
         color: 'blue'
       },
       playoffs: {
         name: 'Playoffs',
         default_duration: 120,
         requires_all: false,
         icon: 'trophy',
         color: 'gold'
       },
       trade_deadline: {
         name: 'Trade Deadline',
         default_duration: 30,
         requires_all: false,
         icon: 'exchange',
         color: 'green'
       }
     }.freeze
     
     def self.get(event_type)
       REGISTRY[event_type.to_sym] || default_config
     end
   end
   ```

## 7. Implementation Phases

### Phase 1: MVP Core (Week 1-2)

1. **Database Setup**
   - Create migrations for all tables
   - Add indexes and constraints
   - Seed data for development

2. **Basic Poll Creation**
   - Commissioner can create poll with time slots
   - Generate shareable link
   - Basic form with server-side validation

3. **Public Response Collection**
   - No-auth response form
   - Store responses with basic validation
   - Prevent duplicate responses per person

4. **Simple Results View**
   - Table showing responses
   - Count of responses per slot
   - Manual decision by commissioner

### Phase 2: Enhanced UX (Week 3)

1. **Stimulus Controllers**
   - Dynamic time slot management
   - Interactive availability grid
   - Client-side validations

2. **Improved Results**
   - Visual availability heatmap
   - Optimal time recommendations
   - Export capability

3. **Response Management**
   - Update existing responses
   - Commissioner can remove spam
   - See who hasn't responded

### Phase 3: Performance & Polish (Week 4)

1. **Performance Optimization**
   - Implement caching strategy
   - Add database views for complex queries
   - Optimize N+1 queries

2. **Security Hardening**
   - Rate limiting implementation
   - Spam protection
   - Audit logging

3. **Polish & Edge Cases**
   - Mobile responsive design
   - Error handling
   - Loading states
   - Empty states

## 8. Testing Strategy

### Unit Tests

```ruby
# spec/models/scheduling_poll_spec.rb
RSpec.describe SchedulingPoll do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:event_type) }
    it { should validate_inclusion_of(:event_type).in_array(SchedulingPoll::EVENT_TYPES.keys.map(&:to_s)) }
  end
  
  describe "event-specific behavior" do
    context "for draft events" do
      let(:poll) { build(:scheduling_poll, event_type: 'draft') }
      
      it "sets appropriate default duration" do
        expect(poll.default_duration_minutes).to eq(180)
      end
    end
    
    context "for trade deadline events" do
      let(:poll) { build(:scheduling_poll, event_type: 'trade_deadline') }
      
      it "allows partial responses" do
        expect(poll.settings[:require_all_responses]).to be_falsey
      end
    end
  end
end

# spec/models/event_poll_factory_spec.rb
RSpec.describe EventPollFactory do
  describe ".build" do
    it "creates appropriate poll builder for event type"
    it "falls back to generic builder for unknown types"
    it "applies event-specific defaults"
  end
end
```

### Integration Tests

```ruby
# spec/requests/scheduling_polls_spec.rb
RSpec.describe "SchedulingPolls" do
  describe "POST /leagues/:league_id/scheduling_polls" do
    context "creating different event types" do
      %w[draft playoffs trade_deadline].each do |event_type|
        context "for #{event_type} events" do
          it "creates poll with appropriate settings"
          it "applies event-specific validations"
          it "generates correct default title"
        end
      end
    end
    
    context "authorization by event type" do
      it "allows commissioner to create draft polls"
      it "allows trade participants to create trade polls"
      it "restricts unauthorized users"
    end
  end
end

# spec/requests/public_scheduling_spec.rb
RSpec.describe "PublicScheduling" do
  describe "POST /schedule/:token" do
    it "creates response without authentication"
    it "stores event-specific preference data"
    it "validates response based on event requirements"
  end
end
```

### System Tests

```ruby
# spec/system/event_scheduling_flows_spec.rb
RSpec.describe "Event Scheduling Flows", type: :system do
  scenario "Commissioner schedules a draft" do
    sign_in commissioner
    visit league_dashboard_path(league)
    
    select "Draft", from: "Schedule Event"
    fill_in "Title", with: "2024 Season Draft"
    add_time_slot("August 15, 2024 7:00 PM", duration: 180)
    click_button "Create Poll"
    
    expect(page).to have_content("Draft Scheduling Poll created")
    expect(page).to have_content("3hr draft window")
  end
  
  scenario "Teams schedule a trade deadline meeting" do
    sign_in team_owner
    visit new_scheduling_trade_path(league_id: league.id)
    
    select_participant("Team A")
    select_participant("Team B")
    add_time_slot("October 15, 2024 8:00 PM", duration: 30)
    click_button "Create Trade Meeting Poll"
    
    expect(page).to have_content("Trade Deadline Meeting")
    expect(page).to have_content("30min")
  end
  
  scenario "Generic event scheduling with custom settings" do
    sign_in commissioner
    visit new_league_scheduling_poll_path(league)
    
    select "League Meeting", from: "Event Type"
    fill_in "Title", with: "Mid-Season Rule Changes"
    fill_in "Custom duration", with: "45"
    add_multiple_time_slots
    click_button "Create Poll"
    
    # Verify event-specific rendering
    expect(page).to have_css(".event-type-badge", text: "League Meeting")
  end
end
```

### Performance Tests

```ruby
# spec/performance/concurrent_responses_spec.rb
RSpec.describe "Concurrent Response Handling" do
  context "for different event types" do
    %w[draft playoffs trade_deadline].each do |event_type|
      it "handles concurrent responses for #{event_type} events" do
        poll = create(:scheduling_poll, event_type: event_type)
        
        threads = 50.times.map do |i|
          Thread.new do
            ResponseRecorder.new.record(
              poll,
              respondent_name: "User #{i}",
              availabilities: { "1" => "available" },
              preferences: event_specific_preferences(event_type)
            )
          end
        end
        
        threads.each(&:join)
        expect(poll.responses.count).to eq(50)
      end
    end
  end
  
  it "optimizes queries for event-specific data" do
    poll = create(:scheduling_poll, :with_responses, event_type: 'draft')
    
    expect {
      SchedulingPoll.with_full_results.find(poll.id)
    }.to perform_under(100).ms
  end
end
```

## 9. Monitoring & Observability

### Key Metrics to Track

1. **Business Metrics**
   ```ruby
   # app/models/scheduling_analytics.rb
   class SchedulingAnalytics
     def self.track_poll_created(poll)
       Ahoy::Event.create(
         name: "poll_created",
         properties: {
           league_id: poll.league_id,
           event_type: poll.event_type,
           time_slots_count: poll.event_time_slots.count,
           league_size: poll.league.members_count,
           settings: poll.settings
         }
       )
     end
     
     def self.track_response_submitted(response)
       poll = response.scheduling_poll
       Ahoy::Event.create(
         name: "scheduling_response_submitted",
         properties: {
           poll_id: poll.id,
           event_type: poll.event_type,
           response_time: response.created_at - poll.created_at,
           availability_score: calculate_availability_score(response)
         }
       )
     end
     
     def self.track_event_scheduled(poll, selected_slot)
       Ahoy::Event.create(
         name: "event_scheduled",
         properties: {
           event_type: poll.event_type,
           lead_time: selected_slot.starts_at - Time.current,
           response_rate: poll.response_rate,
           optimal_score: selected_slot.availability_score
         }
       )
     end
   end
   ```

2. **Performance Metrics**
   - Average page load time for public form
   - Time to create poll with N time slots  
   - Query performance for results page
   - Cache hit rates

3. **Health Metrics**
   - Error rates on form submission
   - Rate limiting trigger frequency
   - Concurrent user handling

### Monitoring Implementation

```ruby
# config/initializers/instrumentation.rb
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  
  if event.payload[:controller] == "PublicSchedulingController"
    StatsD.histogram("scheduling.public_form.duration", event.duration)
    StatsD.increment("scheduling.public_form.requests")
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :track_performance
  
  private
  
  def track_performance
    start = Time.current
    yield
  ensure
    duration = Time.current - start
    Rails.logger.info "[PERF] #{controller_name}##{action_name}: #{(duration * 1000).round}ms"
  end
end
```

### Error Tracking

```ruby
# app/controllers/public_scheduling_controller.rb
class PublicSchedulingController < ApplicationController
  rescue_from RateLimiter::TooManyRequestsError do
    Honeybadger.notify("Rate limit exceeded", context: {
      ip: request.remote_ip,
      poll_id: params[:token]
    })
    render plain: "Too many requests", status: :too_many_requests
  end
end
```

## 10. Technical Risks & Mitigations

### Risk 1: Event Type Proliferation

**Risk**: Adding new event types becomes complex as system grows
**Mitigation**: 
- Event type registry pattern for centralized configuration
- Plugin-style architecture for event-specific logic
- JSONB fields for flexible event metadata
- Well-defined interface for adding new event types

### Risk 2: Concurrent Response Updates

**Risk**: Race conditions when multiple users update responses simultaneously
**Mitigation**: 
- Implement optimistic locking on response records
- Use database-level unique constraints
- Queue updates through Solid Queue if needed
- Event-specific conflict resolution strategies

### Risk 3: Public Form Abuse

**Risk**: Spam submissions, bot attacks, malicious input
**Mitigation**:
- IP-based rate limiting with exponential backoff
- Event-specific rate limits (drafts more restrictive than weekly polls)
- Honeypot fields for bot detection
- Input sanitization and length limits
- Commissioner moderation tools

### Risk 4: Performance with Multiple Event Types

**Risk**: Slow queries as different event types have different query patterns
**Mitigation**:
- Event-specific database indexes
- Separate materialized views per event type
- Caching strategy aware of event types
- Query optimization for common event patterns

### Risk 5: Complex Authorization Rules

**Risk**: Different events have different authorization requirements
**Mitigation**:
- Policy objects for event-specific authorization
- Clear authorization matrix documentation
- Comprehensive test coverage for edge cases
- Fallback to commissioner-only for undefined scenarios

### Risk 6: UI/UX Complexity

**Risk**: Different event types need different UI elements
**Mitigation**:
- Component-based UI architecture
- Event-specific partials and templates
- Consistent base UI with event-specific enhancements
- Progressive disclosure of advanced features

## Implementation Checklist

### Phase 1: Core Infrastructure (Week 1)
- [ ] Create generic database migrations (scheduling_polls, event_time_slots, etc.)
- [ ] Implement base models with event type support
- [ ] Event type registry and configuration system
- [ ] Basic CRUD for polls with event type selection
- [ ] Public response form (server-side, no JS)

### Phase 2: Draft Events MVP (Week 2)
- [ ] Draft-specific poll builder
- [ ] Draft scheduling UI components
- [ ] Draft optimization logic
- [ ] Basic results view for drafts
- [ ] Testing for draft functionality

### Phase 3: Extended Event Types (Week 3)
- [ ] Trade deadline poll support
- [ ] Playoffs scheduling
- [ ] Generic event type support
- [ ] Event-specific authorization rules
- [ ] UI components for each event type

### Phase 4: Enhanced Features (Week 4)
- [ ] Stimulus controllers for dynamic UI
- [ ] Response update capability
- [ ] Advanced availability calculations
- [ ] Rate limiting and security
- [ ] Caching strategy implementation

### Phase 5: Polish & Launch (Week 5)
- [ ] Performance optimization
- [ ] Mobile responsive design
- [ ] Comprehensive test coverage
- [ ] Documentation for adding new event types
- [ ] Monitoring and analytics setup
- [ ] Beta testing with real leagues

## 11. Migration Strategy (If Starting with Draft-Specific)

If development begins with draft-specific naming and later needs to be generalized, here's the migration path:

### Database Migration
```ruby
class GeneralizeSchedulingTables < ActiveRecord::Migration[7.1]
  def change
    # Rename tables
    rename_table :draft_scheduling_polls, :scheduling_polls
    rename_table :draft_time_slots, :event_time_slots
    rename_table :draft_scheduling_responses, :scheduling_responses
    rename_table :draft_slot_availabilities, :slot_availabilities
    
    # Add event_type column
    add_column :scheduling_polls, :event_type, :string
    add_index :scheduling_polls, :event_type
    
    # Migrate existing data
    reversible do |dir|
      dir.up do
        execute "UPDATE scheduling_polls SET event_type = 'draft'"
        change_column_null :scheduling_polls, :event_type, false
      end
    end
    
    # Add new columns for extensibility
    add_column :scheduling_polls, :event_metadata, :jsonb, default: {}
    add_column :event_time_slots, :slot_metadata, :jsonb, default: {}
    add_column :slot_availabilities, :preference_data, :jsonb, default: {}
    
    # Update foreign key column names
    rename_column :event_time_slots, :draft_scheduling_poll_id, :scheduling_poll_id
    rename_column :scheduling_responses, :draft_scheduling_poll_id, :scheduling_poll_id
    rename_column :slot_availabilities, :draft_scheduling_response_id, :scheduling_response_id
    rename_column :slot_availabilities, :draft_time_slot_id, :event_time_slot_id
  end
end
```

### Code Refactoring Steps
1. Update model names and associations
2. Create event type registry
3. Extract draft-specific logic into strategies
4. Update controllers and routes
5. Migrate views to use generic partials
6. Update tests to cover multiple event types

### Gradual Rollout
1. Deploy generic infrastructure alongside draft-specific code
2. Migrate draft functionality to use generic system
3. Add new event types one at a time
4. Deprecate and remove draft-specific code

## Conclusion

This technical plan provides a comprehensive, extensible architecture for implementing league event scheduling within the existing Rails application. By designing for multiple event types from the start, we avoid technical debt and create a flexible system that can grow with product needs.

Key benefits of this generic approach:

1. **Extensibility**: New event types can be added with minimal code changes
2. **Consistency**: Shared infrastructure reduces duplication and bugs
3. **Flexibility**: Event-specific behavior through configuration and strategy patterns
4. **Maintainability**: Clear separation of generic and event-specific code
5. **Performance**: Optimizations can benefit all event types

The design follows established patterns in the codebase (thin controllers, domain objects, no service objects) while introducing minimal external dependencies. The phased approach allows for iterative development, starting with draft scheduling as the primary use case while building infrastructure for future event types.

### Future Event Type Examples

- **Weekly Matchup Reminders**: Quick polls for trash talk sessions
- **Trade Windows**: Coordinate multi-team trade negotiations  
- **Trophy Ceremonies**: Schedule end-of-season celebrations
- **Rule Vote Meetings**: Coordinate league rule change discussions
- **Keeper Deadlines**: Schedule keeper selection meetings

Each new event type would only require:
1. Adding to the EVENT_TYPES registry
2. Creating an optional poll builder class
3. Adding any event-specific UI components
4. Defining authorization rules

This architecture investment upfront will pay dividends as the product evolves.