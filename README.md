# TransportOps Enterprise

Transport & Logistics Management System built with Flutter (Android, iOS, Web) using Clean Architecture.

This repository focuses on real-world CSV-based ingestion and operational tracking (trips, expenses, drivers, trucks).

## Current Status

Done:
- Auth (token storage + auto-login)
- CSV import pipeline with raw data preservation
- Trips listing & filters (local store)
- Expenses: list, create, update, delete, detail
- Expense logs and UI debug panel
- Driver & Truck list wiring
- Modern M3-inspired Expenses UI

In progress / next:
- Backend fixes for expense driver linkage and filters
- Reports (daily/monthly) with KPI panels
- Expense analytics (driver/truck profitability)
- Web UX polish for responsive layouts

## Architecture

Clean Architecture, modular features:
- `lib/features/*` for domain/data/presentation
- `lib/core/*` shared utilities, network, theming
- `lib/shared/*` providers and shared services

## Key Modules

- **Auth**: Laravel Sanctum bearer token
- **Imports**: CSV ingestion pipeline, raw JSON preserved
- **Trips**: local persistence + listing + filters
- **Expenses**: CRUD, filters, logs, analytics-ready
- **Drivers/Trucks**: CRUD list wiring

## Run the App

```bash
flutter pub get
flutter run
```

Web:
```bash
flutter run -d chrome
```

## API Configuration

Default base URL:
```
https://ultraprologistics.com/api/public/api
```

Token is stored using `flutter_secure_storage`.

## Known Backend Dependencies

These are required for full functionality:

1) **CORS (Web)**  
If running on web, ensure backend sends CORS headers and accepts:
- `Authorization` header
- `Content-Type: application/json`
- `Accept: application/json`

2) **Expense driver linkage**  
`POST /expenses` must save `driver_id` and `GET /expenses` must return it.

3) **Expense filters**  
`GET /expenses` should accept:
`driver_id`, `truck_id`, `driver_name`, `plate_no`, `from_date`, `to_date`, `type`

## Local Filtering Behavior

The app provides a fallback for filtering on the client side.  
- Driver filtering works if `driver_id` is returned or if notes contain `Driver: <name>`.

## Useful Paths

- Expenses UI: `lib/features/expenses/presentation/`
- API client: `lib/core/network/api_client.dart`
- CSV pipeline: `lib/features/imports/data/import_pipeline.dart`

## Development Notes

- Branch for ongoing work: `codex/expenses-ui`
- Logs available in Expenses screen via the bug icon
- Use `flutter test` before pushing changes

## Roadmap (V1 → V7)

V1:
- Foundational visibility & manual operations
- CSV import, trips, dashboard, notifications

V2–V7:
- Smart mapping, validations, ledgers, reports
- Workflow automation
- Multi-company
- Analytics & AI assist

---

If you need help running the project or wiring backend updates, open an issue or contact the maintainer.
