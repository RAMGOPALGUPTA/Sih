# Field Drug Testing Mobile App

React Native + Expo Android-first field application.

Phase 1 implements the five-screen workflow from the project specification: officer login, dashboard, test capture, result review and records. It uses SQLite for local persistence, expo-camera for capture, expo-location for GPS, and local evidence hashing. The planned service layer includes storage, location, camera/evidence and API services. fileciteturn51file1L154-L210

## Run

```bash
npm install
npx expo start
```

Use Expo Go for UI testing. A development build is recommended when testing native camera/location behavior on a physical device.

The current result is intentionally `inconclusive` until a validated trained model is installed. The model is an interpretation aid for a presumptive colorimetric field test, not definitive laboratory confirmation.
