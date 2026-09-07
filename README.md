# SIH26231 — Digital Companion for Field Drug Testing

Android-first field companion for colorimetric field-test workflows.

## Prototype

The system captures a test strip together with a reference color card, performs image quality and color calibration, runs on-device classification, creates a tamper-evident evidence record, supports offline-first storage, synchronizes with a REST backend, and provides an operational dashboard.

## Architecture

```text
Flutter Mobile
  Camera → Quality Check → Reference Card Calibration
  → Test ROI → On-device TFLite → Positive / Negative / Inconclusive
  → GPS + Timestamp + Operator ID → SHA-256 → Offline Queue
                         ↓ sync
                    FastAPI REST API
                         ↓
                     PostgreSQL
                         ↓
                 React Dashboard
```

## Repository Layout

- `mobile/` — Flutter Android-first application
- `ml/` — dataset preparation, training, evaluation and TFLite export
- `backend/` — FastAPI service, database models and evidence verification
- `dashboard/` — React operational dashboard
- `docs/` — architecture, API, model and demonstration documentation
- `infra/` — local Docker and deployment configuration

## Safety and scope

The ML component is an interpretation aid for a presumptive colorimetric field test. It is not represented as definitive laboratory confirmation or definitive drug identification.

## Status

Initial repository scaffold. Implementation will proceed as vertical slices, starting with the capture/calibration/ML path.
