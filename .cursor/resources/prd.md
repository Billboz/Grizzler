# Grizzler PRD – Ash/Phoenix/LiveView MVP (v2025-05-26.1)

## 1. Purpose & Goals

| Item                   | Detail                                                                                                                                                                                                                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Core Idea**          | Multiplayer chore & skills tracker for up to 4 active players; gamified points system with daily/weekly scoring and leaderboards.                                                                                                                                                       |
| **Users**              | • **Players** see tasks, run timers, mark complete, view progress<br>• **Admins** create/edit tasks, approve completions, manage player settings, and can also play as players                                                                                                          |
| **Learning Objective** | Build a real-world family application using **Ash Framework 3.5.13 + Phoenix 1.7.21 + LiveView 1.0.14** with Ash-specific TDD methodology from backend resources to LiveView UI                                                                                                         |
| **Deployment**         | Single-tenant Fly.io release, PostgreSQL database                                                                                                                                                                                                                                       |
| **UI/UX**              | • **Single-screen responsive design** (1280x720px primary viewport)<br>• **Dark-mode grayscale palette** inspired by Apple/Google design principles<br>• **Real-time updates** via Phoenix PubSub and LiveView<br>• **Minimalist, functional interface** with subtle micro-interactions |

---

## 2. Technical Stack

| Layer               | Technology                 | Version                      |
| ------------------- | -------------------------- | ---------------------------- |
| **Language**        | Elixir                     | Latest stable                |
| **Platform**        | Erlang/OTP                 | Latest stable                |
| **Core Framework**  | Ash Framework              | 3.5.13                       |
| **Web Framework**   | Phoenix                    | 1.7.21                       |
| **Frontend**        | Phoenix LiveView           | 1.0.14                       |
| **Database**        | PostgreSQL (Ash.Postgres)  | 15.12 (ash_postgres: 2.5.22) |
| **Authentication**  | Ash Authentication         | 4.8.7 (Magic Link strategy)  |
| **Auth UI**         | Ash Authentication Phoenix | 2.7.0                        |
| **Real-time**       | Phoenix PubSub             | 2.1.3                        |
| **HTTP Server**     | Bandit                     | 1.6.11                       |
| **CSS**             | Tailwind CSS               | 0.2.4                        |
| **Admin Interface** | Ash Admin                  | 0.13.5                       |
| **AI Assistance**   | Ash AI                     | 0.1.7                        |
| **Background Jobs** | Ash Oban                   | 0.4.7                        |
| **API (if needed)** | Ash JSON API               | 1.4.32                       |

**Key Dependencies**: Includes comprehensive Ash ecosystem tools for enhanced AI coding assistance and modern Elixir patterns.

---

## 3. Ash Framework vs Phoenix TDD Methodology

### Traditional Phoenix TDD
- Unit tests for contexts, schemas, and controllers
- Integration tests for plug pipelines
- LiveView tests for UI interactions
- Manual setup of database interactions and business logic

### Ash-Specific TDD Approach
- **Resource Tests**: Test Ash resources directly with built-in query and action testing
- **Policy Tests**: Test authorization policies using Ash's policy testing helpers  
- **Action Tests**: Test resource actions (create, read, update, destroy) with Ash test helpers
- **Calculation Tests**: Test calculated fields and aggregates with Ash-specific assertions
- **Reactor Tests**: Test business logic workflows using Ash Reactor patterns
- **LiveView Integration**: Test LiveView components that interact with Ash resources

**Key Difference**: Ash provides built-in testing patterns that work directly with resources and their actions, reducing boilerplate and ensuring tests align with Ash's declarative patterns. This approach tests the business logic layer (Ash resources) separately from the presentation layer (LiveView), leading to more maintainable and focused tests.

---

## 4. User Stories & TDD Requirements

### Authentication Stories
- **As a new user**, I can request a magic link via email so I can access the system securely
- **As a user**, I can click the magic link in my email to log in without a password
- **As an admin**, I can create player accounts for family members so they can receive magic links
- **As the system**, I randomly assign player display numbers (1-4) each session for UI organization

### Player Workflow Stories
- **As a player**, I can view my daily tasks organized by category tabs (Morning, Afternoon, Bedtime, Growth)
- **As a player**, I can click "Begin" to start a task timer and begin working
- **As a player**, I can click "Complete" to stop the timer and submit for approval
- **As a player**, I can see my real-time daily and weekly point totals
- **As a player**, I can view other players' progress in read-only mode
- **As a player**, I can click on any day to see that day's completed tasks and scores
- **As a player**, I can select growth tasks (once per task) and see my accomplishments

### Admin Workflow Stories
- **As an admin**, I can toggle between Player and Admin modes
- **As an admin**, I can create tasks with points (1-1999), categories, descriptions, and requirements
- **As an admin**, I can set task order within categories and day-specific requirements
- **As an admin**, I can set auto-approval for specific task/player combinations
- **As an admin**, I can approve pending task completions
- **As an admin**, I can edit existing tasks without losing historical data
- **As an admin**, I can deactivate tasks (removes at end of day) or remove tasks from specific players
- **As an admin**, I can bulk upload tasks via CSV

### System Behavior Stories
- **As the system**, I create new daily task instances at midnight EST for required tasks
- **As the system**, I reset weekly scores every Saturday at midnight EST
- **As the system**, I track growth task completions permanently to prevent re-selection
- **As the system**, I provide real-time updates when any player completes tasks

---

## 5. Ash Resource Schema Design

### User Resource
```elixir
# Ash resource attributes
- id (primary key, UUID)
- email (unique, case-insensitive)
- name (required)
- role (enum: [:player, :admin])
- avatar (string, optional)
- hashed_token (for magic links)
- confirmed_at (timestamp)
- created_at, updated_at (timestamps)

# Relationships
- has_many :daily_tasks
- has_many :growth_task_completions
- has_many :task_player_settings
- has_many :created_tasks, destination: Task, destination_attribute: :creator_id
```

### Task Resource
```elixir
# Ash resource attributes
- id (primary key, UUID)
- title (required)
- description (optional)
- category (enum: [:morning, :afternoon, :bedtime, :growth])
- points (integer, 1-1999, required)
- list_order (integer, default: 0)
- is_active (boolean, default: true)
- duration_minutes (integer, optional)
- required_sunday through required_saturday (boolean, default: false)
- creator_id (belongs_to User)
- created_at, updated_at (timestamps)

# Relationships
- belongs_to :creator, User
- has_many :daily_tasks
- has_many :growth_task_completions
- has_many :task_player_settings
```

### DailyTask Resource
```elixir
# Ash resource attributes
- id (primary key, UUID)
- user_id (belongs_to User)
- task_id (belongs_to Task)
- date (date, required)
- status (enum: [:pending, :approved, :in_progress])
- time_spent_seconds (integer, default: 0)
- points_awarded (integer, default: 0)
- started_at (utc_datetime, optional)
- completed_at (utc_datetime, optional)
- approved_at (utc_datetime, optional)
- created_at, updated_at (timestamps)

# Relationships
- belongs_to :user, User
- belongs_to :task, Task
```

### GrowthTaskCompletion Resource
```elixir
# Ash resource attributes
- id (primary key, UUID)
- user_id (belongs_to User)
- task_id (belongs_to Task)
- completed_date (date, required)
- time_spent_seconds (integer, required)
- points_awarded (integer, required)
- created_at, updated_at (timestamps)

# Relationships
- belongs_to :user, User
- belongs_to :task, Task
```

### TaskPlayerSetting Resource
```elixir
# Ash resource attributes
- id (primary key, UUID)
- task_id (belongs_to Task)
- user_id (belongs_to User)
- auto_approve (boolean, default: false)
- is_removed (boolean, default: false)
- created_at, updated_at (timestamps)

# Relationships
- belongs_to :task, Task
- belongs_to :user, User
```

---

## 6. Component-Driven Development Sequence

### Phase 1: Authentication Foundation
1. **Magic Link Authentication System**
   - Backend: Implement Ash Authentication with magic link strategy
   - Testing: Ash resource tests for User, authentication action tests
   - Frontend: Magic link request form and confirmation flow
   - **UI Component**: Login/magic link request interface

### Phase 2: User Identity Display
2. **Player Name Display**
   - Backend: User resource with name field, session management
   - Testing: Ash resource tests for User queries, LiveView mount tests
   - Frontend: Display authenticated user's name in top-left corner
   - **UI Component**: Player name header component

### Phase 3: Player Selection & Tabs
3. **Player Tabs Interface**
   - Backend: User queries for all players, session-based player numbering
   - Testing: Ash query tests for player lists, LiveView interaction tests
   - Frontend: Player tabs with current daily scores, selection state
   - **UI Component**: Player tabs with score display

### Phase 4: Weekly Score Block
4. **Weekly Score Display**
   - Backend: DailyTask aggregations, weekly calculation logic
   - Testing: Ash calculation tests, aggregate queries, date-based filtering
   - Frontend: Clickable daily scores (Sun-Sat) with weekly total
   - **UI Component**: Weekly score block with day navigation

### Phase 5: Category Navigation
5. **Category Tabs**
   - Backend: Task resource with category enum, category-based queries
   - Testing: Ash query tests with category filters
   - Frontend: Morning/Afternoon/Bedtime/Growth tab interface
   - **UI Component**: Category tab navigation

### Phase 6: Task Display System
6. **Task Table Structure**
   - Backend: Task resource queries by category, user-specific task lists
   - Testing: Ash resource tests for task queries, category filtering
   - Frontend: 6-column table (Points, Task, Begin, Timer, Complete, Approved)
   - **UI Component**: Task table with empty state

### Phase 7: Task Timer Functionality  
7. **Begin/Timer/Complete Workflow**
   - Backend: DailyTask resource with status transitions, timer tracking
   - Testing: Ash action tests for task state changes, timer calculations
   - Frontend: Begin button, live timer display, complete button
   - **UI Component**: Task timer controls and status display

### Phase 8: Admin Mode Toggle
8. **Player/Admin Mode Switch**
   - Backend: User role queries, authorization policies
   - Testing: Ash policy tests for admin access, role-based queries
   - Frontend: Toggle switch in top-right corner
   - **UI Component**: Admin mode toggle

### Phase 9: Task Creation Interface
9. **Admin Task Creation**
   - Backend: Task resource create actions, validation rules
   - Testing: Ash action tests for task creation, validation tests
   - Frontend: Task creation form with all required fields
   - **UI Component**: Admin task creation modal/form

### Phase 10: Task Approval System
10. **Task Approval Interface**
    - Backend: DailyTask approval actions, points calculation
    - Testing: Ash action tests for approval workflow, point calculations
    - Frontend: Pending tasks list, approval buttons
    - **UI Component**: Admin approval interface

### Phase 11: Real-time Updates
11. **Live Score Updates**
    - Backend: Phoenix PubSub integration with Ash actions
    - Testing: PubSub integration tests, LiveView update tests
    - Frontend: Real-time score updates across all UI components
    - **UI Component**: Real-time data synchronization

### Phase 12: Growth Task Selection
12. **Growth Task Functionality**
    - Backend: GrowthTaskCompletion resource, one-time selection logic
    - Testing: Ash resource tests for growth task constraints
    - Frontend: Growth task selection interface, accomplishments view
    - **UI Component**: Growth task selection and tracking

---

## 7. Feature Requirements

### 7.1 Main Player Interface

**Layout**: Single-screen responsive design (1280x720px)
- **Top Section**: Player name (left), Player/Admin toggle (right)
- **Weekly Score Block**: Clickable daily scores (Sunday-Saturday) + weekly total
- **Player Tabs**: Display up to 4 players with current daily scores
- **Category Tabs**: Morning, Afternoon, Bedtime, Growth
- **Task Table**: 6 columns (Points, Task, Begin, Timer, Complete, Approved)

**Visual Design**:
- Dark-mode grayscale palette (#1C2526 background, #252F31 table background)
- SF Pro typography with appropriate weights and spacing
- Subtle hover states and micro-interactions (0.25s transitions)
- Real-time score updates across all UI elements

### 7.2 Magic Link Authentication

**Magic Link Flow**:
- User enters email address
- System sends magic link via email (using Ash Authentication)
- User clicks link to authenticate
- Session established with secure tokens
- No password required or stored

**Email Integration**:
- Configurable email provider (Swoosh integration)
- Customizable email templates
- Link expiration handling
- Rate limiting for magic link requests

### 7.3 Task Management

**Required Tasks** (Morning, Afternoon, Bedtime):
- Created daily at midnight EST based on day-specific requirements
- Appear in order specified by `list_order` field
- Must be completed daily when required
- Create new instances each day for complete historical tracking

**Growth Tasks**:
- Available in Growth tab for selection
- Each player can complete each growth task only once (permanent tracking)
- Selected tasks move to top of Growth tab for that player
- Completed growth tasks tracked in separate accomplishments view

**Task Workflow**:
1. Player clicks "Begin" → timer starts, task status becomes `:in_progress`
2. Player clicks "Complete" → timer stops, task status becomes `:pending`
3. Admin approves → task status becomes `:approved`, points awarded
4. Auto-approved tasks skip step 3

### 7.4 Admin Interface

**Task Creation Form**:
- Title and description fields
- Category dropdown (Morning, Afternoon, Bedtime, Growth)
- Points field (1-1999 range validation)
- List order field (integer)
- Day-specific requirement checkboxes for each category
- Player-specific auto-approval dropdowns

**Task Management**:
- Edit existing tasks (preserves historical data)
- Deactivate tasks (removes from all players at end of day)
- Remove tasks from specific players (task remains for others)
- Bulk CSV upload with specified column format

**Approval Interface**:
- List of pending task completions across all players
- One-click approval process
- Real-time updates to player scores

### 7.5 Scoring System

**Daily Scoring**:
- Points awarded only upon admin approval (or auto-approval)
- Real-time updates to player UI when points awarded
- Daily totals calculated from approved tasks

**Weekly Scoring**:
- Week runs Sunday-Saturday
- Automatic reset every Saturday at midnight EST
- Historical weekly scores preserved for review

**Leaderboard**:
- Shows current week totals for all players
- Updates in real-time as tasks are approved
- Accessible from weekly score block

---

## 8. Authentication & Security

### Magic Link Authentication
- Ash Authentication with magic link strategy
- Secure token generation and validation
- Email-based authentication flow
- Session management with secure cookies
- No password storage or management required

### Admin Access
- Player/Admin toggle in UI (role-based access via Ash policies)
- Admin role stored in user resource
- Admins can function as players when in Player mode
- Ash policies enforce admin-only actions

### Data Security
- HTTPS everywhere
- Secure session cookies
- No third-party analytics or tracking
- All data stored locally in PostgreSQL via Ash.Postgres

---

## 9. Real-time Features

### Phoenix PubSub Integration
- Real-time score updates across all connected players
- Task completion notifications
- Timer synchronization
- Player presence indicators

### LiveView Reactivity
- Automatic UI updates when data changes
- No page refreshes required
- Smooth transitions and animations
- Optimistic UI updates where appropriate

---

## 10. Background Jobs & Scheduling

### Ash Oban Integration
- Daily task generation at midnight EST
- Weekly score reset every Saturday at midnight EST
- Email sending for magic links
- Cleanup of expired tokens and sessions

### Scheduled Tasks
- Automatic daily task instance creation
- Weekly leaderboard calculations
- System maintenance tasks
- Email queue processing

---

## 11. CSV Bulk Upload Format

**Column Headers**:
```
task_description, points, category, list_order, required_sunday, required_monday, required_tuesday, required_wednesday, required_thursday, required_friday, required_saturday
```

**Example Row**:
```
"Brush Teeth", 150, "morning", 1, true, true, true, true, true, true, true
```

**Validation**:
- Points must be 1-1999
- Category must be valid enum value
- Boolean fields accept true/false or 1/0
- Required validation for description and points
- Processed via Ash resource create actions

---

## 12. Implementation Milestones

| #   | Phase & Component         | Backend Focus                    | Testing Focus                    | Frontend Focus            | Status  |
| --- | ------------------------- | -------------------------------- | -------------------------------- | ------------------------- | ------- |
| 1   | Magic Link Authentication | Ash Auth resource & actions      | Auth action & policy tests       | Login/magic link UI       | Pending |
| 2   | Player Name Display       | User resource queries            | User resource & query tests      | Name display component    | Pending |
| 3   | Player Tabs Interface     | Multi-user queries & numbering   | Player list & session tests      | Player tabs with scores   | Pending |
| 4   | Weekly Score Display      | DailyTask aggregations           | Calculation & aggregate tests    | Weekly score block        | Pending |
| 5   | Category Navigation       | Task category filtering          | Category query tests             | Category tabs             | Pending |
| 6   | Task Table Structure      | Task resource & relationships    | Task resource tests              | 6-column task table       | Pending |
| 7   | Task Timer Functionality  | DailyTask state management       | Action & state transition tests  | Timer controls & display  | Pending |
| 8   | Admin Mode Toggle         | User role & authorization        | Policy & role tests              | Admin toggle switch       | Pending |
| 9   | Task Creation Interface   | Task create actions & validation | Create action & validation tests | Task creation form        | Pending |
| 10  | Task Approval System      | Approval workflow & points       | Approval action tests            | Admin approval interface  | Pending |
| 11  | Real-time Updates         | PubSub integration with Ash      | PubSub & LiveView tests          | Live data synchronization | Pending |
| 12  | Growth Task Selection     | GrowthTaskCompletion constraints | Growth task constraint tests     | Growth task interface     | Pending |

---

## 13. Future Enhancements (Post-MVP)

- **Extensible Categories**: Admin ability to create custom task categories via Ash Admin
- **Advanced Scheduling**: Recurring task patterns using Ash Reactor workflows
- **Reporting Dashboard**: Detailed analytics using Ash calculations and aggregates
- **Mobile Responsive**: Optimize for phone/tablet usage
- **Push Notifications**: Task reminders via Ash notifications
- **Achievement System**: Badges and rewards using Ash state machines
- **AI Task Generation**: Automated suggestions using Ash AI integration

---

## 14. Technical Considerations

### Performance
- Ash.Postgres optimizations with proper indexing
- Efficient real-time updates with targeted PubSub messages
- Optimized LiveView updates using Ash's change tracking
- Resource query optimization using Ash's built-in performance tools

### Scalability
- Single-family deployment for MVP
- Ash multi-tenancy support for future expansion
- Resource-based architecture scales naturally
- PubSub scaling considerations for future multi-tenant use

### Error Handling
- Ash's built-in error handling patterns
- User-friendly error messages via Ash error translation
- Comprehensive logging using Ash's audit trail features
- Graceful degradation when real-time features fail

---

## 15. Acceptance Criteria

### Player Experience
- ✅ Players can authenticate via magic link
- ✅ Players can complete daily tasks with timer tracking
- ✅ Real-time score updates visible immediately
- ✅ Weekly progress clearly displayed and accessible
- ✅ Growth tasks selectable once per player
- ✅ Other players' progress viewable in read-only mode

### Admin Experience  
- ✅ Task creation with all required attributes
- ✅ Bulk task upload via CSV
- ✅ Task approval workflow functional
- ✅ Player-specific settings configurable via Ash Admin
- ✅ Historical data preserved during task modifications

### System Reliability
- ✅ Daily task generation at midnight EST via Ash Oban
- ✅ Weekly score reset Saturday midnight EST
- ✅ Growth task completion tracking permanent
- ✅ Real-time updates working across all connected users
- ✅ Data integrity maintained using Ash's built-in constraints

---

**Document Version**: v2025-05-26.1  
**Target Framework**: Ash 3.5.13 + Phoenix 1.7.21 + LiveView 1.0.14  
**Development Approach**: Ash-Specific TDD with Component-Driven Sequence  
**Primary User**: Family of 4 players + admin(s)  
**AI Assistance**: Enhanced with Ash AI 0.1.7 and Ash ecosystem tooling