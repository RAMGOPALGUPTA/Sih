# SIH — Digital Companion for Field Drug Testing

Complete monorepo for an offline-first field-test companion: Flutter mobile app, image/calibration pipeline, TensorFlow training/export, FastAPI API, PostgreSQL, React dashboard, Docker and CI.

## Status
This repository is rebuilt from a clean tree. The ML pipeline trains on operator-supplied labelled images; no fabricated model or accuracy is committed.

## Quick start
```bash
docker compose -f infra/docker-compose.yml up --build
```
API: http://localhost:8000/docs
Dashboard: http://localhost:5173

### Train the model
```bash
cd ml
python -m pip install -r requirements.txt
python train.py --data dataset/raw --output artifacts
python export_tflite.py --model artifacts/model.keras --output ../mobile/assets/model.tflite
```
Put images in `ml/dataset/raw/{positive,negative,inconclusive}` before training.

### Mobile
Install Flutter, then:
```bash
cd mobile
flutter pub get
flutter run
```

The system is an interpretation aid for a presumptive colorimetric field test. It is not definitive laboratory confirmation or definitive drug identification.
