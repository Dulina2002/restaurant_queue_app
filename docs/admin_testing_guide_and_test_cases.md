# DineQueue - Admin Module Testing & Documentation Guide

---

## 1. Overview of the Admin Module

The **Admin** module manages the DineQueue platform operations, multi-tenant restaurants, user roles, security, emergency controls, and platform broadcasts.

### Key Screens & Features in Admin:
1. **Admin Dashboard Screen (`lib/screens/admin/admin_dashboard_screen.dart`)**
   - **Header & Metrics**: System status, total active restaurants, registered users, active queues.
   - **Partner Restaurants View**: Manage all restaurants across the platform.
2. **User & Role Management (`admin_users_view.dart`)**
   - View all registered users across all roles (`Admin`, `Manager`, `Receptionist`, `Customer`).
   - Invite new staff/manager users with custom roles.
   - Change user role dynamically.
   - Suspend / Activate user accounts.
   - Delete user accounts.
3. **Broadcasts & Emergency System (`admin_broadcasts_system_backend.md`)**
   - **Send Platform Alerts**: Send priority alerts (`Normal`, `Warning`, `Urgent`) visible to all restaurants and diners.
   - **Platform Freeze**: Emergency freeze button to halt incoming queue reservations during peak incidents.
   - **Flush Waitlists**: Emergency queue flush to clear waitlists.
4. **Switch Role Utility Dialog**
   - Admin utility to switch views directly to Customer, Receptionist, or Manager.

---

## 2. Commands to Run Automated Admin Tests

### Command 1: Run Full Admin Test Suite (with line-by-line names)
```bash
flutter test test/admin_dashboard_test.dart test/admin_users_test.dart test/admin_broadcasts_system_test.dart test/admin_switch_role_redirect_test.dart --reporter=expanded
```

### Command 2: Run Just the Admin Dashboard & Emergency Controls Test
```bash
flutter test test/admin_dashboard_test.dart --reporter=expanded
```

### Command 3: Run User & Role Management Tests
```bash
flutter test test/admin_users_test.dart --reporter=expanded
```

### Command 4: Run Broadcast & Emergency Queue Flush Tests
```bash
flutter test test/admin_broadcasts_system_test.dart --reporter=expanded
```

---

## 3. What the Admin Tests Verify

| # | Test Area | Verification Description |
|---|---|---|
| **1** | **Admin Dashboard Snapshots** | Verifies empty state handling, real data loading, and partner restaurants view. |
| **2** | **Error Fallbacks** | Verifies network/backend error handling and fallback display when reading database records. |
| **3** | **Platform Broadcasts** | Validates alert creation with title, message, and priority levels (`Normal`, `Warning`, `Urgent`). |
| **4** | **Platform Freeze** | Tests the emergency freeze confirmation modal and toggle state updates. |
| **5** | **Emergency Queue Flush** | Verifies the waitlist flush confirmation and reports flushed entry counts. |
| **6** | **User List Rendering** | Validates loading users, emails, assigned roles, and status from the backend. |
| **7** | **User Invitation** | Tests inviting new team members with specific roles and error validation. |
| **8** | **Role Modification** | Tests promoting or changing roles (e.g. from Customer to Receptionist or Manager). |
| **9** | **Account Suspension & Activation** | Tests suspending user access and re-activating suspended users. |
| **10**| **User Deletion** | Validates safety prompt and user removal from the platform. |
| **11**| **Role Switch Redirection** | Tests switching from Admin session to other app roles. |

---

## 4. Manual Testing & Screenshot (SS) Guide for Admin

### How to Access Admin on Emulator:
1. Run the app:
   ```bash
   flutter run -d emulator-5554
   ```
2. On Sign In screen, log in with an **Admin account** (or sign up with role **Admin**).
3. The app will launch into the **Admin Dashboard**.

### Recommended Screenshots for Admin Doc:
1. `ss_admin_01_dashboard.png`: Admin Dashboard overview & statistics.
2. `ss_admin_02_restaurants.png`: Partner restaurants management table.
3. `ss_admin_03_users.png`: User management screen with roles (`Admin`, `Manager`, `Customer`).
4. `ss_admin_04_invite_user.png`: Invite user dialog with role selection.
5. `ss_admin_05_broadcasts.png`: Broadcast alerts list & "Send Alert" modal.
6. `ss_admin_06_platform_freeze.png`: Emergency Platform Freeze confirmation modal.
7. `ss_admin_07_flush_waitlists.png`: Flush waitlists action dialog.
8. `ss_admin_08_terminal_tests_passed.png`: Terminal output showing all 32 tests passing with `All tests passed!`.
