# Super Admin Feature Plan

## Overview
Create a super admin system that allows designated administrators to manage site content and user access without storing super admin status in the users table.

## Core Requirements
- Super admin status stored separately from user table
- Super admin dashboard interface
- Ability to designate super admins
- Secure access control

## Technical Architecture

### 1. Database Design

#### New Table: `super_admins`
```sql
CREATE TABLE super_admins (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Rationale:**
- Separate table prevents accidental user elevation
- Foreign key ensures referential integrity
- Cascade delete removes super admin status if user is deleted

#### Indexes
- `index_super_admins_on_user_id` (unique)

### 2. Model Design

#### SuperAdmin Model
- Belongs to User
- Validates uniqueness of user_id
- Provides helper methods for checking super admin status

#### User Model Enhancement
- Has one SuperAdmin (optional)
- Helper method: `super_admin?`

### 3. Authentication & Authorization

#### Devise Integration
- Extend Devise to check super admin status
- Add super admin check to application controller
- Create before_action filters for super admin routes

#### Route Protection
- Namespace super admin routes under `/admin`
- Require super admin authentication for all admin routes

### 4. Controller Structure

#### Admin::BaseController
- Inherits from ApplicationController
- Includes super admin authentication
- Provides common admin functionality

#### Admin::DashboardController
- Main dashboard view
- Overview of system statistics
- Quick access to admin functions

#### Admin::UsersController
- List all users
- View user details
- Basic user management (future)

#### Admin::SuperAdminsController
- List current super admins
- Add new super admins
- Remove super admins

### 5. View Structure

#### Layout
- `app/views/layouts/admin.html.erb`
- Admin-specific navigation
- Different styling from main app

#### Dashboard Views
- `app/views/admin/dashboard/index.html.erb`
- `app/views/admin/users/index.html.erb`
- `app/views/admin/super_admins/index.html.erb`

### 6. Routes

```ruby
namespace :admin do
  get 'dashboard', to: 'dashboard#index'
  resources :users, only: [:index, :show]
  resources :super_admins, only: [:index, :create, :destroy]
end
```

## Implementation Phases

### Phase 1: Foundation (MVP)
1. Create SuperAdmin model and migration
2. Add super admin helper methods to User model
3. Create Admin::BaseController with authentication
4. Create basic admin dashboard
5. Create SuperAdmins controller for management
6. Add admin layout and styling

### Phase 2: User Management (Future)
1. Create Admin::UsersController
2. Add user listing and detail views
3. Implement user approval/blocking functionality

### Phase 3: Content Management (Future)
1. Add content moderation features
2. Implement approval workflows
3. Add audit logging

## Security Considerations

### Authentication
- Super admin status checked on every admin request
- No way to elevate regular users through normal user flows
- Separate session handling for admin area

### Authorization
- All admin routes protected by super admin check
- CSRF protection on all admin forms
- Rate limiting on admin actions

### Data Protection
- Super admin actions logged for audit trail
- Sensitive operations require confirmation
- No accidental user elevation possible

## Testing Strategy

### Unit Tests
- SuperAdmin model validations
- User model super_admin? method
- Controller authorization logic

### Integration Tests
- Admin route protection
- Super admin creation/removal flows
- Dashboard access control

### System Tests
- Complete admin workflow
- Security boundary testing
- User elevation prevention

## Migration Strategy

### Database Migration
```ruby
class CreateSuperAdmins < ActiveRecord::Migration[7.0]
  def change
    create_table :super_admins do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :super_admins, :user_id, unique: true
  end
end
```

### Seed Data
- Create initial super admin through Rails console
- Document super admin creation process

## Future Considerations

### Scalability
- Consider role-based permissions for different admin levels
- Plan for admin activity logging
- Design for multiple super admins

### User Experience
- Admin dashboard analytics
- Bulk operations for user management
- Search and filtering capabilities

### Monitoring
- Admin action audit logs
- Performance monitoring for admin operations
- Alert system for critical admin actions

## Success Criteria
- [ ] Super admin can be designated without user table modification
- [ ] Admin dashboard is accessible and functional
- [ ] Super admin status is secure and cannot be accidentally granted
- [ ] Basic user listing is available
- [ ] Super admin management interface works
- [ ] All admin routes are properly protected
- [ ] Tests pass and cover security scenarios 