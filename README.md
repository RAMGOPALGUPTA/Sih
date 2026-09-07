# SIH26231 — Digital Companion for Field Drug Testing

An Android-first digital companion for colorimetric field-test workflows.

## System

```text
FIELD OFFICER
    │
    ▼
Flutter Mobile App
    │  Camera
    │  Image Quality
    │  Reference-Card Calibration
    │  Test ROI Extraction
    │  TensorFlow Lite Inference
    │  GPS + Timestamp + Operator ID
    │  SHA-256 Evidence Integrity
    │  Offline-First Case Queue
    │
    │ sync
    ▼
FastAPI REST API
    │
    ▼
PostgreSQL
    │
    ▼
React Operations Dashboard
```

## Monorepo

```text
sih/
├── mobile/                 # Flutter Android-first application
├── ml/                     # preprocessing, training, evaluation, TFLite export
├── backend/                # FastAPI API and evidence verification
├── dashboard/              # React operational dashboard
├── docs/                   # architecture, API, ML and demo documentation
├── infra/                  # Docker/deployment configuration
└── .github/workflows/      # CI/CD
```

## ML

Prototype classes: `positive`, `negative`, `inconclusive`.

The model pipeline uses the reference color card for calibration before classification. Low-quality or low-confidence observations can remain inconclusive. The model is an interpretation aid for a presumptive field test, not definitive laboratory confirmation or definitive drug identification.

## Evidence

Each case will bind the case ID, operator ID, timestamp, GPS coordinates, image SHA-256, canonical payload SHA-256, model version and application version. Verification recomputes hashes and reports whether the evidence matches the recorded integrity values.

## Development order

1. Mobile capture and calibration
2. ML preprocessing/training/evaluation
3. On-device inference
4. Evidence hashing and offline storage
5. FastAPI + PostgreSQL synchronization
6. React dashboard and integrity verification
7. Integration tests and deployment
