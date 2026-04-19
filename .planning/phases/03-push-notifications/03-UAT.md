---
status: partial
phase: 03-push-notifications
source: [SUMMARY.md]
started: 2026-04-19T00:00:00Z
updated: 2026-04-19T00:00:00Z
---

## Current Test

number: 1
name: App Web/Windows no crashea por Firebase
expected: |
  La app arranca en Web o Windows sin errores relacionados con Firebase.
  El guard kIsWeb/Platform.isAndroid evita que FcmService.initialize() se ejecute
  fuera de Android. Las pantallas funcionan con normalidad.
awaiting: user response

## Tests

### 1. App Web/Windows no crashea por Firebase
expected: La app arranca en Web o Windows sin errores relacionados con Firebase. Guard kIsWeb/Platform.isAndroid activo — FcmService no ejecuta código Firebase fuera de Android.
result: issue
reported: "Web (Chrome) arranca OK. Windows falla en build: CMake no puede extraer firebase_cpp_sdk_windows_12.7.0.zip desde ruta OneDrive. Error: archive_write_finish_entry File size could not be restored."
severity: major

### 2. Backend endpoint FCM token existe
expected: POST /api/fcm/token con body {"usuarioId": 1, "token": "test-token"} y header Authorization devuelve HTTP 200 (token guardado en tabla fcm_tokens).
result: pass

### 3. PLACEHOLDER comprensible
expected: El fichero android/app/google-services.json.PLACEHOLDER tiene instrucciones claras: URL Firebase Console, applicationId correcto (com.example.meltic_gmao_app), dónde poner el fichero descargado y cómo obtener serviceAccountKey.json para el backend.
result: pass
note: Verificado en sesión anterior — instrucciones claras y completas.

### 4. Build Android (bloqueado sin google-services.json)
expected: Sin google-services.json real, flutter build apk falla en la fase de Gradle. Esperado — se desbloquea siguiendo el PLACEHOLDER.
result: blocked
blocked_by: third-party
reason: "google-services.json no configurado — seguir PLACEHOLDER para activar Firebase real antes de la defensa"

## Summary

total: 4
passed: 2
issues: 1
pending: 0
skipped: 0
blocked: 1

## Gaps

- truth: "La app arranca en Windows sin errores de build relacionados con Firebase"
  status: failed
  reason: "User reported: CMake no puede extraer firebase_cpp_sdk_windows_12.7.0.zip desde ruta OneDrive. firebase_core añade dependencia nativa C++ que rompe Windows build."
  severity: major
  test: 1
  artifacts: [Frontend/meltic_gmao_app/pubspec.yaml, Frontend/meltic_gmao_app/android/app/build.gradle.kts]
  missing: [fix para excluir Firebase C++ SDK de Windows build, o mover firebase packages a android-only]
