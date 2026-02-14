# Transport Ops Enterprise

Transport Ops Enterprise is a logistics operations platform built for **mobile + web** using Flutter, backed by a Laravel API.

It supports end-to-end workflows for:
- orders and trips
- drivers and trucks
- clients and providers (vendors)
- expenses and reports
- document handling (waybills, driver iqama, truck istimara)
- export workflows (ZIP, PDF, Excel)

## Stack

- Frontend: Flutter (Riverpod state management)
- Backend: Laravel 10 + Sanctum token auth
- Database: MariaDB/MySQL
- File storage: Laravel public storage

## Project Structure

- Flutter app: `./` (this repository)
- Laravel API (local deployment used in development): `/Users/naveedabbas/Sites/api`

## Main Modules Implemented

- Authentication with role handling (`owner_view`, `admin`)
- Dashboard (owner/admin views)
- Trips module
- Orders module
- Drivers module
- Trucks module
- Clients module
- Providers module
- Expenses module
- Reports module

## Key Business Flows

### 1) Orders + Trips

- Orders can be created with route and client.
- Trips can be linked to an order **or** created standalone.
- For order-linked trips:
  - order financials are used as **default template values**
  - values are editable per trip before save
  - per-trip values remain source of truth for reporting

### 2) Location UX

- Autocomplete for `from` and `to` locations
- Add location on-the-spot if not found
- Works in both order and trip create flows

### 3) Documents

- Waybill upload per trip
- Driver iqama upload
- Truck registration/istimara upload
- Missing-doc indicators in order details
- Upload actions available directly from order trip rows

### 4) Order Document ZIP

- Download ZIP from order detail
- Generates one **combined PDF per trip**
  - driver document first
  - truck document second
  - supports source docs as image or PDF
- Naming format: `driverName truckNo.pdf`

### 5) Order Summary Exports

- Summary PDF export
- Summary Excel export (`.xlsx`) in **vertical block format**:
  - `Truck 1` + detail rows
  - `Truck 2` + detail rows
- Excel export tuned to keep only visible business columns (`A`, `B`) for clean presentation

## Current UI/UX Direction

- Unified visual language across dashboard/trips/orders/clients/providers/drivers/trucks
- Trip detail intentionally hides financial cards/breakdown (as requested)
- Edit/Delete actions available in both list and detail screens where applicable

## API Endpoints Added/Used (Highlights)

### Orders
- `GET /api/orders`
- `POST /api/orders`
- `GET /api/orders/{id}`
- `PUT /api/orders/{id}`
- `DELETE /api/orders/{id}`
- `GET /api/orders/{id}/docs-zip`
- `GET /api/orders/{id}/docs-zip-download?token=...`
- `GET /api/orders/{id}/summary-pdf`
- `GET /api/orders/{id}/summary-pdf-download?token=...`
- `GET /api/orders/{id}/summary-excel`
- `GET /api/orders/{id}/summary-excel-download?token=...`

### Trips
- `GET /api/trips`
- `POST /api/trips`
- `GET /api/trips/{id}`
- `PUT /api/trips/{id}`
- `DELETE /api/trips/{id}`
- `POST /api/trips/{id}/waybills`
- `DELETE /api/trips/{id}/waybills/{fileId}`

### Documents
- `POST /api/drivers/{id}/iqama`
- `POST /api/trucks/{id}/registration-card`

### Reports
- Expense and operational reporting endpoints including exports are wired and integrated with UI.

## Deletion Rules

- Order delete is blocked if linked trips exist.
- Trip delete is blocked if linked expenses or invoice records exist.

## Local Environment Notes

Frontend currently targets local API base URL:
- `http://127.0.0.1:8000`

Backend app path used in development:
- `/Users/naveedabbas/Sites/api`

## Run Instructions

### Flutter App

```bash
flutter pub get
flutter run
```

### Laravel API

```bash
cd /Users/naveedabbas/Sites/api
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

## Recent Work Completed (Summary)

- Upgraded and aligned app/API connectivity to local server
- Implemented complete Orders module with trip linkage
- Added clients/providers management and connectivity across modules
- Added robust location autocomplete + inline location creation
- Added advanced order docs ZIP with combined per-trip PDFs
- Added summary PDF and Excel exports for order truck/driver data
- Added provider display fixes and richer trip mapping fields
- Added missing-doc upload actions from order detail
- Added edit/delete flows in order and trip pages
- Removed financial UI from trip detail page per business requirement
- Added extensive schema-safe API changes and response normalization

## Notes

If you are presenting to management or clients:
- Use **Download Excel** from order detail for copy/paste table workflows in email.
- Use **Download Docs ZIP** for bundled trip-wise document packs.
