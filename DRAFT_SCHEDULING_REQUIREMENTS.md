# Draft Scheduling Feature - Product Requirements Document

## 1. Problem Definition and Opportunity

### Problem Statement
Fantasy football commissioners currently struggle to coordinate draft times with 8-12 league members, often resorting to inefficient methods like group texts, emails, or third-party polling tools. This creates friction at the start of each fantasy season and can delay league setup.

### Opportunity
Create a seamless, integrated scheduling tool that allows commissioners to quickly gather availability from all league members without requiring logins or external tools, establishing the product as the go-to solution for league coordination.

### Opportunity Solution Tree (OST)

```
Desired Outcome: Increase commissioner satisfaction and league activation rates
│
├── Opportunity: Reduce time to finalize draft scheduling
│   ├── Solution: In-app scheduling polls
│   ├── Solution: Calendar integration (future)
│   └── Solution: Smart time suggestions (future)
│
├── Opportunity: Increase participation in scheduling decisions
│   ├── Solution: No-login required responses
│   ├── Solution: Mobile-friendly interface
│   └── Solution: Reminder notifications (future)
│
└── Opportunity: Simplify commissioner's decision-making
    ├── Solution: Visual availability heatmap
    ├── Solution: Conflict highlighting
    └── Solution: Optimal time recommendations (future)
```

## 2. User Outcomes

### Primary Outcomes
1. **For Commissioners**: Reduce draft scheduling time from days to hours
2. **For League Members**: Provide input on draft timing without friction
3. **For the Business**: Increase commissioner tool adoption and engagement

### Jobs to be Done (JTBD)
- **Commissioner**: "When I need to schedule our annual draft, I want to quickly gather everyone's availability so I can pick a time that works for most members"
- **League Member**: "When my commissioner asks about draft availability, I want to easily share my preferences without creating another account"

## 3. Success Metrics

### Leading Indicators
- % of leagues creating scheduling polls (target: 60% in first season)
- Average response rate per poll (target: 80%+)
- Time from poll creation to first response (target: <2 hours)

### Lagging Indicators
- Average time to finalize draft schedule (target: <48 hours)
- Commissioner NPS for scheduling feature (target: 40+)
- % of commissioners who use feature again next season (target: 85%+)

### Health Metrics
- Poll abandonment rate (monitor for <20%)
- Error rate on submission (monitor for <2%)
- Page load time for response form (monitor for <2 seconds)

## 4. User Stories with Acceptance Criteria

### Epic: Draft Scheduling
**As a** commissioner  
**I want to** create and manage scheduling polls  
**So that** I can coordinate the best draft time for my league

#### Story 1: Create Scheduling Poll
**As a** commissioner  
**I want to** create a draft scheduling poll with multiple time options  
**So that** I can gather availability from league members

**Acceptance Criteria:**
- Commissioner can access scheduling feature from league dashboard
- Can add unlimited time slot options (date, time, duration)
- Each time slot shows in league's timezone
- Can preview the poll before creating
- Generates unique, shareable link upon creation
- Link is displayed prominently with copy-to-clipboard functionality

#### Story 2: Share Poll Link
**As a** commissioner  
**I want to** easily share the scheduling poll  
**So that** all league members can respond

**Acceptance Criteria:**
- Shareable link is short and memorable (e.g., commishtools.com/schedule/ABC123)
- Link can be copied with one click
- Pre-formatted message templates for common platforms (SMS, email, Discord)
- Link remains active until commissioner closes poll

#### Story 3: Respond to Poll (No Login)
**As a** league member  
**I want to** respond to the scheduling poll without logging in  
**So that** I can quickly provide my availability

**Acceptance Criteria:**
- Link opens directly to response form (no login required)
- Form clearly shows all proposed time slots
- Can enter name/username (with validation for uniqueness)
- Can select availability for each slot:
  - ❌ "Can't make it"
  - 🟡 "Could work if needed"  
  - ✅ "Perfect timing"
- Can update response by returning to same link
- Confirmation message after submission

#### Story 4: View Poll Results
**As a** commissioner  
**I want to** see aggregated availability results  
**So that** I can make an informed scheduling decision

**Acceptance Criteria:**
- Real-time results dashboard showing:
  - Response count and percentage
  - Availability grid (members × time slots)
  - Visual indicators (green/yellow/red) for each response
  - Optimal time recommendations based on responses
- Can see who hasn't responded yet
- Can close poll to prevent further responses
- Export results as CSV (future enhancement)

#### Story 5: Manage Poll Responses
**As a** commissioner  
**I want to** manage and moderate poll responses  
**So that** I can ensure data quality

**Acceptance Criteria:**
- Can view all individual responses with timestamps
- Can remove duplicate or invalid responses
- Can manually add responses for offline members
- See response history if someone updates their availability

## 5. Key Assumptions and Risks

### Assumptions to Test
1. **Value Risk**: Commissioners find integrated scheduling more valuable than existing tools
   - Test: User interviews with 10 commissioners about current process
   - Prototype: Figma mockup for feedback sessions

2. **Usability Risk**: Non-logged-in users can successfully complete the form
   - Test: Unmoderated usability test with 5 league members
   - Success criteria: 80%+ completion rate

3. **Feasibility Risk**: System can handle concurrent responses without conflicts
   - Test: Technical spike on optimistic locking for responses
   - Prototype: Proof of concept with 20 concurrent users

4. **Viability Risk**: Feature drives sufficient engagement to justify development
   - Test: Feature fake door test with current commissioners
   - Success criteria: 40%+ click-through rate

### Risk Mitigation Strategy
- **Security**: Implement rate limiting and CAPTCHA for public forms
- **Spam**: Allow commissioners to require email verification (optional)
- **Data Privacy**: Clear data retention policy (90 days post-draft)
- **Abuse**: Ability to report and block malicious responses

## 6. MVP Scope Definition

### In Scope for MVP
- Create poll with multiple datetime slots
- Generate shareable public link
- Collect responses without login (name + availability)
- Display results grid to commissioner
- Close/reopen poll functionality
- Mobile-responsive design
- Basic email notification to commissioner when poll is created

### Out of Scope for MVP (Future Iterations)
- Calendar integration (Google, Apple, Outlook)
- Automated reminders to non-respondents
- Smart time suggestions based on historical data
- Recurring event scheduling
- Time zone detection and conversion
- In-app notifications
- Poll templates
- Bulk import of league member contacts
- SMS notifications
- Advanced analytics and insights

### Technical Constraints for MVP
- No external dependencies beyond existing stack
- Reuse existing authentication for commissioners
- Simple public URLs (no complex token generation)
- Store responses in PostgreSQL (no caching layer)

## 7. Future Considerations

### Phase 2: Enhanced Scheduling (3-6 months)
- Calendar integration for availability import
- Automated reminder system
- Time zone intelligence
- Poll templates for common events

### Phase 3: Beyond Draft Scheduling (6-12 months)
- Schedule any league event (playoffs, trades, etc.)
- Recurring event support
- Integration with league calendar
- Voting on non-scheduling decisions

### Platform Expansion
- Native mobile app considerations
- API for third-party integrations
- Slack/Discord bot integration

### Monetization Opportunities
- Premium features for leagues (advanced analytics, unlimited polls)
- White-label solution for other sports
- API access for enterprise customers

## Discovery Plan

### Week 1: Problem Validation
- Interview 10 commissioners about current scheduling process
- Map current journey and pain points
- Validate assumed problems exist

### Week 2: Solution Testing
- Create low-fi prototypes
- Test with 5 commissioners and 10 league members
- Iterate based on feedback

### Week 3: Technical Feasibility
- Spike on public form security
- Test concurrent response handling
- Validate no-login architecture

### Week 4: Launch Readiness
- Finalize MVP scope with engineering
- Create measurement plan
- Plan beta rollout strategy

## Definition of Done
- All acceptance criteria met
- Feature documented in help center
- Analytics events implemented
- Load tested for 100 concurrent users
- Security review completed
- Beta tested with 5 real leagues

This comprehensive requirements document follows the Cagan/Torres methodology by focusing on outcomes over outputs, emphasizing continuous discovery, and maintaining a clear connection between user problems and proposed solutions. The MVP scope is intentionally minimal to enable rapid learning and iteration based on real user feedback.