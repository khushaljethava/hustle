# Hustle - All-in-One Freelancer App: User Story & Feature Overview

## Executive Summary

**Hustle** is a comprehensive mobile application designed for freelancers and independent contractors to streamline their workflow. It provides an integrated platform for managing tasks, tracking time, invoicing clients, and monitoring earnings—all in one place.

---

## Product Vision

Enable freelancers to work efficiently by offering a unified workspace for:
- Organizing and prioritizing work
- Accurately tracking billable hours in real-time
- Generating professional invoices with recurring billing
- Managing client relationships
- Monitoring income and productivity

**Core Value Proposition**: Freelancers spend less time on administrative tasks and more time earning money.

---

## Application Architecture

### Technology Stack
- **Framework**: Flutter (Cross-platform: iOS, Android, Web, Windows, Linux, macOS)
- **State Management**: BLoC pattern with flutter_bloc
- **Database**: SQLite (local-first with cloud sync via Firebase)
- **Backend**: Firebase (Authentication, Real-time Sync)
- **Monetization**: RevenueCat (subscription management)
- **Additional Features**: PDF generation, CSV export, push notifications

### Key BLoCs (State Management Modules)
- **AuthBloc**: Authentication state (login, logout, onboarding)
- **TaskBloc**: Task CRUD operations and status management
- **TimerBloc**: Real-time timer and time entry tracking
- **InvoiceBloc**: Invoice creation, modification, and status tracking
- **ClientBloc**: Client profile and contact management
- **DashboardBloc**: Aggregated metrics and earnings overview

---

## Core Features & User Stories

### 1. **Authentication & Onboarding**

#### Story 1.1: User Sign-Up via Google
As a new freelancer, I want to sign up using my Google account so that I can quickly get started without creating another password.

- Sign in with Google using Firebase Auth
- Automatic profile creation with email and display name
- First-time user redirected to onboarding flow
- Onboarding screens explain app features and benefits
- Skip onboarding is tracked locally (SharedPreferences)

#### Story 1.2: User Authentication Persistence
As a returning user, I want to stay logged in so that I don't have to authenticate every time I open the app.

- Firebase Auth persists user session across app launches
- AuthBloc checks authentication status on app startup
- Auto-navigation to dashboard if authenticated
- Auto-navigation to login screen if not authenticated

---

### 2. **Client Management**

#### Story 2.1: Create and Store Client Information
As a freelancer, I want to store client details including name, contact info, company, and hourly rate so that I can quickly reference them when creating tasks and invoices.

**Data Stored**:
```
- Client ID (UUID)
- Name
- Email
- Phone
- Company
- Default Hourly Rate
- Currency (e.g., USD, EUR)
- Notes
- Creation & Update Timestamps
- Archive Status (soft delete)
```

#### Story 2.2: Manage Client Rates
As a freelancer with multiple clients, I want to set different hourly rates for each client so that invoicing is accurate.

- Store default hourly rate per client
- Override rate on a per-task or per-invoice basis
- Support multiple currencies per client

#### Story 2.3: Archive Clients
As a freelancer, I want to archive inactive clients without deleting them so that my client list stays clean.

- Soft delete (archive) functionality
- Archived clients excluded from active lists
- Can restore archived clients

---

### 3. **Task Management**

#### Story 3.1: Create Tasks with Client Assignment
As a freelancer, I want to create tasks, assign them to clients, set priorities, and add descriptions so that I can organize my workload.

**Task Data**:
```
- Task ID
- Title & Description
- Assigned Client (optional)
- Status: pending, in_progress, completed
- Priority: low, medium, high
- Hourly Rate (uses client default if not set)
- Estimated Hours
- Due Date
- Billable Flag
- Timestamps
```

#### Story 3.2: Track Task Status
As a freelancer, I want to update task status (pending → in_progress → completed) so that I can track project progress.

- Status transitions: pending → in_progress → completed
- Completed tasks locked from editing
- Status updates timestamped
- Overdue detection: tasks past due date with pending/in_progress status

#### Story 3.3: Set Task Priorities
As a freelancer, I want to prioritize tasks (low, medium, high) so that I focus on urgent work first.

- Visual priority indicators in task list
- Filter/sort by priority
- Notifications for high-priority overdue tasks

#### Story 3.4: Mark Tasks as Billable or Non-Billable
As a freelancer, I want to distinguish billable work from non-billable work so that I accurately report earnings.

- Billable flag on tasks
- Non-billable time entries don't count toward earnings
- Filter tasks by billable status

---

### 4. **Time Tracking**

#### Story 4.1: Start/Stop Real-Time Timer
As a freelancer actively working, I want to start a timer so that I can accurately track how long I've spent on a task in real-time.

**Timer Features**:
```
- Start timer (creates a TimeEntry with startTime)
- Timer runs continuously (UI updates every second)
- Visible elapsed time display
- Stop timer (sets endTime, calculates duration)
- Only one timer can run at a time
```

#### Story 4.2: Manually Log Time Entries
As a freelancer, I want to manually create time entries for work I did but didn't track in real-time so that I account for all billable hours.

- Specify task, client, start time, end time, notes
- Duration calculated from start/end times
- Retroactively add time entries
- Edit existing time entries

#### Story 4.3: View Time Entry History
As a freelancer, I want to see all my time entries for a day, week, or month so that I can verify my tracked time before invoicing.

- Time entries grouped by date or by client
- Display duration, task, client, and earnings for each entry
- Filter by date range, client, billable status
- Summary: total hours, total earnings

#### Story 4.4: Calculate Earnings from Time Tracked
As a freelancer, I want to see how much I've earned based on tracked time and hourly rates so that I can track income.

**Calculation Logic**:
```
For each billable TimeEntry:
  earnings = (duration_in_minutes / 60) * hourly_rate

TotalEarnings = sum of all billable time entry earnings
```

- Real-time earnings display on timer screen
- Historical earnings per day/week/month
- Breakdown by client

---

### 5. **Invoice Management**

#### Story 5.1: Create Invoice from Tasks or Time Entries
As a freelancer, I want to create an invoice for a client that automatically includes tasks/time entries so that I can quickly generate professional invoices.

**Invoice Structure**:
```
- Invoice ID & Number (auto-incrementing)
- Client Details (name, email)
- Line Items:
  - Description
  - Quantity (hours)
  - Rate per unit
  - Amount (quantity × rate)
- Subtotal (sum of line amounts)
- Tax Rate (%, e.g., 10%)
- Tax Amount (calculated)
- Total (subtotal + tax)
- Currency
- Status: draft, sent, paid
- Issue Date & Due Date
- Notes (payment terms, thanks, etc.)
- Recurring? (yes/no + interval)
- Template (classic, modern, etc.)
```

#### Story 5.2: Set Invoice Status (Draft → Sent → Paid)
As a freelancer, I want to track invoice lifecycle so that I know which invoices are outstanding and which have been paid.

- Draft: invoice saved but not sent
- Sent: invoice sent to client (marked with send date)
- Paid: client has paid (marked with paid date)
- Overdue detection: sent invoices past due date
- Notifications for overdue invoices

#### Story 5.3: Generate PDF Invoices
As a freelancer, I want to export invoices as PDFs so that I can send them to clients or keep records.

- Professional PDF with branding elements
- Includes all invoice details
- Downloadable on mobile
- Shareable (via email, messaging apps)
- Multiple template styles available

#### Story 5.4: Create Recurring Invoices
As a freelancer with retainer clients, I want to set up recurring invoices that auto-generate on a schedule so that I don't manually create the same invoice every month.

**Recurring Invoice Features**:
```
- Recurring Flag (boolean)
- Interval: weekly, bi-weekly, monthly, quarterly, yearly
- Next Recurring Date (auto-calculated)
- Background job processes recurring invoices:
  - Checks if today >= recurringNextDate
  - Creates new invoice invoice (duplicate + increment number)
  - Sets new recurringNextDate
  - Runs at app startup & periodically
```

#### Story 5.5: Customize Invoice Templates
As a freelancer, I want to choose different invoice layouts/styles so that my invoices match my brand.

- Multiple templates: classic, modern, detailed, minimal
- Template choice stored per invoice
- Apply template globally for future invoices

#### Story 5.6: Calculate Taxes Automatically
As a freelancer in a region with sales tax, I want taxes calculated automatically so that invoices are accurate.

- Tax rate specified per invoice (or default)
- Tax amount = subtotal × tax_rate%
- Tax displayed as line item on invoice
- Total = subtotal + tax

---

### 6. **Dashboard & Analytics**

#### Story 6.1: View Income Overview
As a freelancer, I want to see my total earnings, earnings by client, and earnings trends so that I understand my income.

**Dashboard Metrics**:
```
- This Month Earnings (billable time entries)
- Last Month Earnings
- Outstanding Invoices (sent, unpaid)
- Paid This Month
- Total Billable Hours (this month)
```

#### Story 6.2: View Tasks Overview
As a freelancer, I want to see how many tasks are pending, in progress, and completed so that I can gauge workload.

- Count of tasks by status
- Overdue tasks highlighted
- Quick actions to update status

#### Story 6.3: View Charts and Trends
As a freelancer, I want to visualize my earnings, tasks, and activities over time so that I can identify patterns and busy periods.

- Chart: Earnings by month (line/bar chart)
- Chart: Earnings by client (pie/bar chart)
- Chart: Time spent by client or task (pie chart)
- Chart: Task completion rate (trend)

---

### 7. **Notifications & Reminders**

#### Story 7.1: Receive Overdue Invoice Reminders
As a freelancer, I want to be notified about unpaid invoices past their due date so that I can follow up with clients.

- Local push notification when invoice becomes overdue
- Notification shows client name and overdue days
- Tap to open invoice
- Notifications sent when app starts (in background task)

#### Story 7.2: Receive Overdue Task Reminders
As a freelancer, I want to be notified about tasks past their due date so that I stay on top of deadlines.

- Local push notification for overdue tasks
- Notification shows task title and client
- Only for incomplete tasks (not completed)

---

### 8. **Settings & Preferences**

#### Story 8.1: Toggle Light/Dark Mode
As a freelancer, I want to switch between light and dark themes so that I can use the app comfortably in any lighting.

- Light theme (default)
- Dark theme
- Theme preference saved locally
- ValueListenable notifier for reactive theme switching
- Theme applied globally via MaterialApp

#### Story 8.2: Manage Account Settings
As a freelancer, I want to view and edit my profile information so that my data is correct.

- Display name
- Email
- Default currency
- Default tax rate
- Timezone
- Business name (optional)

#### Story 8.3: Manage Subscription
As a freelancer, I want to subscribe to premium features so that I can unlock advanced functionality.

- Free tier: limited features (e.g., max 10 clients)
- Premium tier: unlimited features
- RevenueCat integration for subscriptions
- Paywall screen showing feature comparison
- Subscription status display in settings

#### Story 8.4: Export Data
As a freelancer, I want to export my data (clients, tasks, invoices, time entries) as CSV so that I can backup or analyze in Excel.

- CSV export with auto-generated filename
- Timestamp in filename
- All records exported
- Shareable via email or cloud storage

---

### 9. **Profile & Account**

#### Story 9.1: View Profile
As a freelancer, I want to see my profile with account details and statistics so that I have a quick reference of my account.

- Profile picture (from Google account)
- Name and email
- Total earnings (all-time)
- Total clients
- Total invoices
- Account creation date
- Link to settings

#### Story 9.2: Logout
As a freelancer, I want to log out so that my account is secure on shared devices.

- Logout button in profile
- Clear authentication state via AuthBloc
- Return to login screen
- Local data persisted (can be cleared separately)

---

## Key Data Models

### Client
- id, name, email, phone, company, defaultRate, currency, notes, isArchived, timestamps

### Task
- id, title, description, clientId, status, priority, hourlyRate, estimatedHours, dueDate, isBillable, timestamps

### TimeEntry
- id, taskId, clientId, startTime, endTime, duration, notes, isBillable, hourlyRate, timestamps

### Invoice
- id, invoiceNumber, clientId, items[], subtotal, taxRate, taxAmount, total, currency, status, issueDate, dueDate, isRecurring, recurringInterval, recurringNextDate, template, timestamps

### InvoiceItem
- id, invoiceId, description, quantity, rate, amount

---

## Business Logic & Workflows

### Workflow 1: "Create Task → Log Time → Generate Invoice"
1. Freelancer creates task for Client A
2. Starts timer and works
3. Stops timer → time entry logged
4. Creates invoice with timeentries
5. Sets invoice status to Sent
6. Receives notification when invoice due date passes
7. Marks invoice as Paid when client pays

### Workflow 2: "Set Up Recurring Invoice"
1. Freelancer creates a base invoice for retainer client
2. Enables "Is Recurring" + sets interval to "Monthly"
3. Background service checks daily
4. When recurring date arrives, new invoice auto-created
5. Freelancer reviews and sends to client

### Workflow 3: "Track Multiple Clients in a Day"
1. Freelancer starts timer on Task A (Client 1)
2. Stops timer → time entry logged
3. Starts timer on Task B (Client 2)
4. Stops timer → time entry logged
5. Dashboard shows earnings from both clients
6. Can generate separate invoices for each client

---

## Tech Implementation Details

### Authentication Flow
```
App Startup
  ├─ Check Firebase Auth Token
  ├─ If valid → AuthAuthenticated state
  │  └─ Check onboarding preference
  │     ├─ If onboarded → Show MainShell (dashboard)
  │     └─ If not onboarded → Show OnboardingScreen
  └─ If not valid → AuthUnauthenticated state
     └─ Show LoginScreen (with Google Sign-In)
```

### Background Tasks
- **Recurring Invoices**: Processed on app startup, checks if recurring date passed
- **Overdue Notifications**: Scheduled when app starts, checks all invoices and tasks
- **Non-Fatal Errors**: Background tasks don't crash app if they fail

### Local-First Architecture
- All data stored locally in SQLite
- Firebase integration for auth only (future: cloud sync)
- Offline-capable: app works without internet
- Data syncs when connection available

---

## Premium Features (Paywall)

**Free Tier**:
- Up to 10 clients
- Up to 50 invoices
- Basic templates

**Premium Tier**:
- Unlimited clients and invoices
- All invoice templates
- Advanced analytics
- CSV export
- Priority support

---

## User Acquisition & Monetization

- **Free trial**: Full access for 14 days
- **In-app purchase**: Subscription via RevenueCat
- **Target**: Freelancers, small agencies, independent contractors

---

## Future Enhancements (Roadmap)

1. **Cloud Sync**: Real-time sync via Firebase Firestore
2. **Multi-user Support**: Team management for small agencies
3. **Client Portal**: Clients can view invoices and make payments
4. **Payment Integration**: Accept payments directly in app (Stripe, PayPal)
5. **Expense Tracking**: Log and categorize business expenses
6. **Tax Reports**: Generate tax-ready reports
7. **Mobile App Notifications**: Better push notification handling
8. **Calendar View**: Visual calendar of tasks and availability
9. **Client Messaging**: Built-in communication history
10. **Integrations**: Sync with QuickBooks, Wave, Zapier, etc.

---

## Success Metrics

- **User Retention**: 60%+ monthly active users
- **Feature Adoption**: 80%+ of premium users using time tracking
- **Invoice Accuracy**: 100% calculated correctly
- **App Performance**: <2s invoice generation, responsive UI
- **Notification Delivery**: 95%+ of overdue reminders delivered
- **Subscription Churn**: <5% monthly churn rate

---

## Conclusion

Hustle is a comprehensive solution for freelancers to manage ihre entire work lifecycle—from planning tasks and tracking time to invoicing and monitoring income. By providing a unified, intuitive interface for these interconnected activities, Hustle empowers freelancers to focus on what they do best: their work, while the app handles the administrative overhead.
