# Dairy Shop — Customer Khata Scaffold

Minimal offline-first slice: customer profiles + purchases (khata) + payments,
using Flutter + Drift (SQLite). This is step 1 of the bigger app — sales,
suppliers, expenses, and multi-device sync come later.

## What's here

- `lib/database/database.dart` — the 3 tables (Customers, Purchases, Payments)
  and all the query/update logic, including due calculation and a combined
  history stream for a customer's detail page.
- `lib/screens/customer_list_screen.dart` — list of customers with their due
  (red) or credit (green), and an "add customer" dialog with an opening-due
  field for existing customers.
- `lib/screens/customer_detail_screen.dart` — due summary, "Add Purchase" /
  "Add Payment" buttons, and a chronological transaction history.
- `lib/main.dart` — wires the database in with `provider`.

## Running it

1. Create a new Flutter project and copy these files in (or point an existing
   project's `lib/` and `pubspec.yaml` at these):
   ```
   flutter create dairy_shop_app
   ```
   then replace its `lib/` folder and `pubspec.yaml` with the ones here.

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Generate Drift's code (`database.g.dart` — not included here since it's
   machine-generated):
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run:
   ```
   flutter run
   ```

## Notes

- Due logic: `currentDue = openingDue + sum(purchases) - sum(payments)`.
  Overpaying is allowed — due goes negative and the UI shows it as a green
  "Credit" balance, same as your chicken-shop khata app.
- Nothing here talks to a server — it's a local SQLite file in the device's
  app documents folder. Multi-device sync gets layered on top later without
  needing to change this schema much.
- Next slice, whenever you're ready: Sales (cash), Purchases from suppliers,
  and the daily closing screen.
