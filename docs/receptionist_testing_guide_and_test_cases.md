# DineQueue - Receptionist Module Testing & Documentation Guide

---

## 1. Overview of the Receptionist Module

The **Receptionist** module handles daily front-of-house operations: welcoming guests, tracking reservations, monitoring live restaurant floor tables, managing the virtual queue, and adding walk-in parties.

### Key Screens & Features in Receptionist:
1. **Receptionist Dashboard (`lib/screens/receptionist/receptionist_dashboard_screen.dart`)**
   - Active restaurant switcher (Ocean Bistro, Nihonbashi, China town, etc.).
   - Shift metrics (Expected arrivals, currently seated, waiting in queue, available floor tables).
   - Expected arrivals feed with party size, time, and assigned tables.
   - Quick action: **Add Walk-In Party**.
   - Quick action: **Reassign Table** dialog.
2. **Reservations Management (`lib/screens/receptionist/reservation_summary_screen.dart`)**
   - Daily reservations summary with filter tabs (`All`, `Confirmed`, `Completed`, `Cancelled`).
   - Guest search by name or reservation code.
   - Real-time seat or cancel actions.
3. **Live Floor Overview (`lib/screens/receptionist/floor_overview_screen.dart`)**
   - Real-time floor plan layout with all physical tables.
   - Table status color coding (`Available`, `Occupied`, `Reserved`, `Disabled`).
   - Interactive table status modal: seat party, change status, or free up table.
4. **Live Virtual Queue (`lib/screens/receptionist/live_queue_screen.dart`)**
   - Active waiting queue entries ordered by wait position.
   - One-tap customer call button (notifies the customer that their table is ready).
   - Seat party button and remove party button.
5. **Receptionist Staff Profile (`lib/screens/receptionist/receptionist_profile_screen.dart`)**
   - Staff identity, active restaurant assignment, and secure logout.

---

## 2. Command to Run Automated Receptionist Tests

Run this command in your terminal to see all tests pass line-by-line:

```bash
flutter test test/receptionist_all_features_test.dart --reporter=expanded
```

---

### What it Displays in Your Terminal:

```text
00:00 +0: Receptionist Dashboard & Navigation Tests 1. Receptionist Dashboard renders RECEPTIONIST role badge and metrics
00:00 +1: Receptionist Dashboard & Navigation Tests 2. Reservation Summary screen renders filter tabs and reservations list
00:00 +2: Receptionist Dashboard & Navigation Tests 3. Floor Overview screen renders floor layout and table management
00:00 +3: Receptionist Dashboard & Navigation Tests 4. Live Queue screen renders active queue management and party calls
00:00 +4: Receptionist Dashboard & Navigation Tests 5. Receptionist Profile screen renders staff details and logout options
00:00 +5: Receptionist Operations & Dialog Tests 6. Reassign Table dialog allows selecting new floor table
00:00 +6: Receptionist Operations & Dialog Tests 7. Add Walk-In dialog renders input fields and guest counter
00:00 +7: Receptionist Operations & Dialog Tests 8. Receptionist context persists selected restaurant and prevents revert
00:00 +8: All tests passed!
```

---

## 3. What the Receptionist Tests Verify

| # | Test Area | Verification Description |
|---|---|---|
| **1** | **Receptionist Dashboard** | Checks header with `RECEPTIONIST` badge, active restaurant dropdown, and shift metric cards. |
| **2** | **Reservations Summary** | Verifies filtering by status, reservation list, guest details, and arrival times. |
| **3** | **Floor Overview** | Validates real-time floor plan tables (`Available`, `Occupied`, `Reserved`). |
| **4** | **Live Queue Screen** | Checks queue tickets in order, wait time counter, and call next party actions. |
| **5** | **Staff Profile** | Checks staff details, email, and Sign Out capabilities. |
| **6** | **Reassign Table Dialog** | Tests opening table reassignment, selecting another table, and saving the updated assignment. |
| **7** | **Add Walk-In Party Dialog**| Tests entering guest name, phone, party size counter, and submitting to waitlist. |
| **8** | **Restaurant Switching** | Verifies switching the active restaurant and persistence without reverting. |

---

## 4. Manual Testing & Screenshot (SS) Guide for Receptionist

### How to Open Receptionist Screen on Emulator:
1. Run:
   ```bash
   flutter run -d emulator-5554
   ```
2. In the app, sign in with a **Receptionist account** (or sign up with role **Receptionist**).
3. The app will launch into the **Receptionist Dashboard**.

### Recommended Screenshots for Receptionist Doc:
1. `ss_rec_01_dashboard.png`: Receptionist Dashboard with metrics and active restaurant.
2. `ss_rec_02_reassign_table.png`: Reassign Table dialog showing floor tables.
3. `ss_rec_03_walk_in_dialog.png`: Add Walk-In party dialog with party size counter.
4. `ss_rec_04_reservations.png`: Reservations Management screen with filter tabs.
5. `ss_rec_05_floor_overview.png`: Live Floor Overview table grid with statuses.
6. `ss_rec_06_live_queue.png`: Live Queue screen with waiting parties and call buttons.
7. `ss_rec_07_profile.png`: Receptionist Profile screen.
8. `ss_rec_08_terminal_tests_passed.png`: Terminal output showing all 8 tests passing with `All tests passed!`.
