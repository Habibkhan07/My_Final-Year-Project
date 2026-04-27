# Technician Dashboard API

**Endpoint**: `GET /api/technicians/dashboard/`

Returns the technician's daily overview including their current wallet balance, online status, profile picture, metrics for the day, and upcoming jobs.

## Authentication
- Requires `IsAuthenticated`.
- The authenticated user must have an associated `TechnicianProfile` (`user.tech_profile`). If not, a `403 Permission Denied` standard error envelope is returned.

## Query Parameters
None.

## Sample Response
```json
{
  "wallet_balance": 1500.00,
  "is_online": true,
  "profile_picture": "http://127.0.0.1:8000/media/tech_profiles/ali.png",
  "up_next_job": {
    "job_id": 99482,
    "service_title": "AC Deep Wash",
    "scheduled_time": "2026-04-26T14:00:00Z",
    "customer_name": "Ali R.",
    "customer_phone": "+923001234567",
    "address_text": "14 Street, Gulberg III",
    "lat": 31.5204,
    "lng": 74.3587
  },
  "later_today_jobs": [
    {
      "job_id": 99483,
      "service_title": "Ceiling Fan Repair",
      "scheduled_time": "2026-04-26T16:00:00Z",
      "address_text": "DHA Phase 5"
    }
  ],
  "metrics": {
    "jobs_completed_today": 2,
    "cash_collected_today": 3500.00
  }
}
```

### Notes on Fields:
- `profile_picture`: Absolute URL to the technician's profile image. Nullable if not set.
- `up_next_job`: Nullable if no upcoming jobs exist for the day. Returns the most urgent confirmed job scheduled for now or later today.
- `up_next_job.customer_phone`: E.164 string used by the dashboard's Contact Customer button to launch a `tel:` deep link. Nullable if the customer has no phone on file (legacy accounts). The Flutter UI hides/disables the call action when null.
- `later_today_jobs`: Empty array `[]` if no remaining jobs are scheduled for today. Excludes the `up_next_job`.
- `metrics`: Calculated strictly from jobs with status `COMPLETED` for the current day.
