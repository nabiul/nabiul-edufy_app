# Nabiul Edufy App

Flutter client for the Laravel project in `../nabiul-edufy`.

## Included

- Admin-only username/email login using Laravel Sanctum
- Persisted mobile session and logout
- Dashboard with school name and notice count
- Notice list and notice details
- Logged-in user profile
- Academic overview with current session statistics
- Permission-aware academic session, class and section management
- Session, class and section filters
- Student search, list and full details
- Permission-aware student creation and profile/academic assignment editing
- Audited single-student promotion with target session, class, section and roll
- Same-session class/section transfer with operator audit history
- Daily class attendance register with bulk present/absent marking and remarks
- Monthly class report and student-wise present/absent date history
- Fees dashboard and collection totals
- Fee purposes and monthly templates
- Payment history and student monthly due breakdown
- Permission-aware fee collection with due and overpayment protection
- Date-wise collection reports with daily and fee-purpose breakdowns
- Filterable outstanding due list and server-verified payment receipts
- Accounts dashboard and calculated balances
- Income, expense, purpose and transfer reporting
- Permission-aware income and expense entry with confirmation
- Searchable account transaction history
- Date/account-wise cash-flow reports with daily and purpose breakdowns
- Server-verified income and expense voucher details
- Android, iOS, web, macOS, Windows, and Linux Flutter targets

## Run locally

Start the Laravel API from the backend directory:

```bash
cd ../nabiul-edufy
php artisan serve --host=0.0.0.0 --port=8000
```

Then start Flutter:

```bash
flutter run
```

The default API URL targets the MAMP project path:
`http://10.0.2.2/nabiul-edufy/api/v1` on an Android emulator and
`http://127.0.0.1/nabiul-edufy/api/v1` on other local targets. On a physical
device, tap the server URL on the login screen and replace the host with the
computer's local network IP. It can also be overridden at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000/api/v1
```

Use an HTTPS API URL for production builds.

## Development guidelines

Before opening a pull request, run:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Keep environment-specific API URLs out of source control. Use the login
screen's server URL setting for a physical device, or pass `API_BASE_URL` with
`--dart-define` for builds and CI. Never commit `.env` files, signing keys,
tokens, or production credentials.

Use focused commits with an imperative subject, for example:
`Fix due report pagination` or `Add attendance session filter`.

## API endpoints

| Method | Endpoint | Authentication |
| --- | --- | --- |
| POST | `/api/v1/login` | Public |
| GET | `/api/v1/me` | Bearer token |
| GET | `/api/v1/dashboard` | Bearer token |
| GET | `/api/v1/notices` | Bearer token |
| GET | `/api/v1/academic/summary` | Admin bearer token |
| GET | `/api/v1/academic/years` | Admin bearer token |
| POST | `/api/v1/academic/years` | Elevated admin role |
| PUT | `/api/v1/academic/years/{id}` | Elevated admin role |
| GET | `/api/v1/academic/levels` | Admin bearer token |
| POST | `/api/v1/academic/levels` | `class create` permission |
| PUT | `/api/v1/academic/levels/{id}` | `class edit` permission |
| GET | `/api/v1/academic/sections` | Admin bearer token |
| POST | `/api/v1/academic/sections` | `section create` permission |
| PUT | `/api/v1/academic/sections/{id}` | `section edit` permission |
| GET | `/api/v1/academic/students` | Admin bearer token |
| GET | `/api/v1/academic/students/{id}` | Admin bearer token |
| POST | `/api/v1/academic/students` | `student create` permission |
| PUT | `/api/v1/academic/students/{id}` | `student edit` permission |
| POST | `/api/v1/academic/students/{id}/promote` | `promotion create` permission |
| PUT | `/api/v1/academic/students/{id}/transfer` | `student edit` permission |
| GET | `/api/v1/academic/attendance` | `attendance` permission |
| PUT | `/api/v1/academic/attendance` | `attendance` permission |
| GET | `/api/v1/academic/attendance/report` | `attendance` permission |
| GET | `/api/v1/fees/summary` | Admin bearer token |
| GET | `/api/v1/fees/purposes` | Admin bearer token |
| GET | `/api/v1/fees/templates` | Admin bearer token |
| GET | `/api/v1/fees/payments` | Admin bearer token |
| GET | `/api/v1/fees/payments/{id}` | Admin bearer token |
| GET | `/api/v1/fees/report` | Admin bearer token |
| GET | `/api/v1/fees/dues` | Admin bearer token |
| GET | `/api/v1/fees/students/{id}` | Admin bearer token |
| POST | `/api/v1/fees/students/{id}/payments` | `fee collection` permission |
| GET | `/api/v1/accounts/summary` | Admin bearer token |
| GET | `/api/v1/accounts/list` | Admin bearer token |
| GET | `/api/v1/accounts/purposes` | Admin bearer token |
| GET | `/api/v1/accounts/transactions` | Admin bearer token |
| GET | `/api/v1/accounts/transactions/{type}/{id}` | Admin bearer token |
| GET | `/api/v1/accounts/transfers` | Admin bearer token |
| GET | `/api/v1/accounts/report` | Admin bearer token |
| POST | `/api/v1/accounts/deposits` | `deposit create` permission |
| POST | `/api/v1/accounts/withdrawals` | `withdraw create` permission |
| POST | `/api/v1/logout` | Bearer token |

Login accepts `login`, `password`, and optional `device_name`. The `login` field
may contain either a username or email address.

Admin app access is allowed for the `developer`, `super admin`, `admin`,
`master`, and `global` roles.

Run Laravel migrations after pulling backend changes so attendance-taken days
are tracked even when every student is absent:

```bash
php artisan migrate
```
