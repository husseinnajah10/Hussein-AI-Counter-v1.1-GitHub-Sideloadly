# Student AI Counter 3.0 — Golden Gate

**Designed By Hussein Najah** — © 2026 Hussein Najah. All Rights Reserved.

A SwiftUI iOS 17+ classroom people counter based on the working Hussein AI Counter 2.0 source code. Branding redesigned; original app identifier and existing lecture-history storage key deliberately retained for in-place updates.

## Features

- Brand-new **face inside detection square** 1024×1024 opaque PNG icon and Golden Gate gold arch splash screen.
- Calm **teal + gold** interface, statistics-first home screen, custom animated/raised selected bottom navigation (Statistics, Camera, History, Settings).
- Separate camera modes: **live count** and **photo count** (capture or Photos picker).
- Physical front/back camera switch, 0.5× ultra-wide on supported back cameras, tap to focus, pinch-to-zoom inside preview, torch when available.
- Apple Vision face detection with upper-body detections as fallback; matched face/body pairs are counted once. Unseen faces are not portrayed as guessed head boxes. Temporal track smoothing reduces jitter.
- Latest **count + face count + timestamp** locally persisted about every **0.8 seconds** *when detection output arrives*. Stable live counts separately added to lecture history after about one second, subject to duplicate suppression; captured/photo counts also logged. **No captured camera images are stored in history**.
- Daily statistics, average/highest result, CSV export; Arabic/English toggle.
- Optional **local display profile** with a guest mode. This is intentionally **NOT genuine Apple/Google/email authentication** and no password is collected.
- Adjustable soft feedback and sounds.

## Upgrade guarantees and limitations

- Original bundle identifier: `com.husseinnajah.HusseinAICounter`.
- Old `UserDefaults` key: `HusseinAICounter.CountingHistory.v1`, preserving prior lecture records on a normal update. **Export CSV before sideloading; data preservation is not guaranteed by all signing methods**.
- App version `3.0`, build `4`; display name `Student AI Counter`. Target executable remains `HusseinAICounter` so the existing Xcode scheme and build pipeline remain compatible.
- Detections are best-effort, never guaranteed to find people behind obstructions or outside the view. Face detection is *not facial recognition or student identification*. The UI does not label specific student identities.
- There is **no guaranteed hard real-time latency bound**: `0.8 seconds` is a target write interval for an *available detection result*, not a promise under all device loads, camera changes or lighting conditions.
- No Mac/Xcode SDK in the authoring environment: Swift syntax/project metadata/static asset checks passed, but the full iOS SDK build and camera tests are still required via GitHub Actions and a physical device.

## Source layout

- `HusseinAICounter/HusseinAICounterApp.swift` — app entry, bilingual direction and shared state
- `HusseinAICounter/AppTheme.swift` — colors, feedback, local settings and footer
- `HusseinAICounter/SplashView.swift` — animated Golden Gate start screen
- `HusseinAICounter/HomeView.swift` — statistics, live/photo camera, history, settings, preview overlays
- `HusseinAICounter/CameraCounter.swift` — AVFoundation + Vision detector, camera switching, tracking and zoom
- `HusseinAICounter/CountingHistory.swift` — existing history and rapid local last-observation snapshot
- `HusseinAICounter/Assets.xcassets/` — generated app icon and Golden Gate mark
- `.github/workflows/build-ipa.yml` — produces unsigned IPA using hosted macOS
- `tests/validate_release.py` — offline release smoke checks

For step-by-step Windows deployment, see `INSTALL-WINDOWS-AR.md`.
