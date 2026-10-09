# DineQueue - Manager Module Testing & Documentation Guide

---

## 1. Overview of the Manager Module

The **Manager** module is responsible for dining operations, venue floor configurations, live menu management (including 86'd out-of-stock items), and yield optimization.

### Key Screens & Features in Manager:
1. **Manager Dashboard (`lib/features/manager/presentation/screens/manager_dashboard_screen.dart`)**
   - **Header**: `MANAGER` role badge, active managed restaurant selector dropdown, add new restaurant option.
   - **Role Switcher Modal**: Quick role switcher to preview other user portals.
2. **Segment Tab 1: Overview**
   - Shift metrics (Average wait time, active parties waiting, available tables, table turnover rate).
   - Hourly seating velocity chart.
   - Quick action: **AI Floor Optimizer** (AI seating and yield recommendations).
   - Quick action: **Quick-Turn Tables** (bulk turn tables to available & alert waiting queue).
3. **Segment Tab 2: Physical Tables (`tables_tab_widget.dart`)**
   - Complete physical table list & grid layout toggle.
   - Filter by restaurant zone (`Main Dining`, `Terrace`, `VIP Room`, `Bar Seating`).
   - Add new physical table, configure seats, edit table, or delete table.
4. **Segment Tab 3: Live Menu (`live_menu_tab_widget.dart`)**
   - Dish catalog with live sync connected banner.
   - Instant **86 Dish** (toggle out-of-stock items in real-time across customer app).
   - Add new dish with price, category, photo URL, and preparation time.
   - Filter dishes by category (`Appetizers`, `Mains`, `Desserts`, `Beverages`).

---

## 2. Command to Run Automated Manager Tests

Run this command in your terminal to see all Manager tests pass line-by-line:

```bash
flutter test test/manager_all_features_test.dart --reporter=expanded
```

---

### What it Displays in Your Terminal:

```text
00:00 +0: Manager Dashboard & Segment Navigation Tests 1. Manager Dashboard renders MANAGER role badge and header
00:00 +1: Manager Dashboard & Segment Navigation Tests 2. Tapping Tables tab switches to table management layout
00:00 +2: Manager Dashboard & Segment Navigation Tests 3. Tapping Live Menu tab switches to menu dish controls
00:00 +3: Manager Dashboard & Segment Navigation Tests 4. Role header tap displays Role Switcher modal
00:00 +4: Manager Floor & Menu Operations Tests 5. TablesTabWidget renders physical floor layout and management options
00:00 +5: Manager Floor & Menu Operations Tests 6. LiveMenuTabWidget renders menu sync banner and dish management
00:00 +6: Manager Floor & Menu Operations Tests 7. RestaurantDatabaseService adds manager restaurant to real stream
00:00 +7: All tests passed!
```

---

## 3. What the Manager Tests Verify

| # | Test Area | Verification Description |
|---|---|---|
| **1** | **Manager Dashboard** | Verifies header with `MANAGER` badge, screen title, and segment pills (`Overview`, `Tables`, `Live Menu`). |
| **2** | **Tables Tab Navigation** | Tests switching from Overview to the Tables segment tab and loading table controls. |
| **3** | **Live Menu Tab Navigation** | Tests switching to the Live Menu tab and displaying menu synchronization tools. |
| **4** | **Role Switcher Modal** | Tests tapping the role badge and viewing options to switch to Customer, Receptionist, or Admin. |
| **5** | **Physical Tables Management** | Verifies table grid/list rendering, seating capacity, zones, and status. |
| **6** | **Live Menu Sync & Dish Control** | Verifies the live sync banner, dish items, category filters, and out-of-stock controls. |
| **7** | **Add Managed Restaurant** | Verifies creating a new restaurant in the database and streaming it to the manager selector. |

---

## 4. Manual Testing & Screenshot (SS) Guide for Manager

### How to Open Manager Screen on Emulator:
1. Run:
   ```bash
   flutter run -d emulator-5554
   ```
2. On the Sign In screen, log in with a **Manager account** (or sign up with role **Manager**).
3. The app will launch directly into the **Manager Dashboard**.

### Recommended Screenshots for Manager Doc:
1. `ss_mgr_01_dashboard.png`: Manager Dashboard Overview tab with KPI metrics and velocity chart.
2. `ss_mgr_02_tables_tab.png`: Tables tab with physical floor layout and Add Table button.
3. `ss_mgr_03_menu_tab.png`: Live Menu tab showing dishes and 86 out-of-stock toggle.
4. `ss_mgr_04_ai_optimizer.png`: AI Floor Optimizer bottom sheet with recommendations.
5. `ss_mgr_05_quick_turn.png`: Quick-Turn Tables modal with bulk table turning.
6. `ss_mgr_06_role_switcher.png`: Role Switcher bottom sheet.
7. `ss_mgr_07_terminal_tests_passed.png`: Terminal output showing all 7 tests passing with `All tests passed!`.
