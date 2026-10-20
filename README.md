# Hussein AI Counter — Native iOS 2.0 (Build 3)

**Designed By Hussein Najah**  
**© 2026 Hussein Najah. All Rights Reserved.**

A fully local, original **SwiftUI + AVFoundation + Apple Vision** iPhone project based on the user's successfully installed v1.1 source. **The user's original HN icon and splash image are preserved byte-for-byte.** The bundle identifier is unchanged: `com.husseinnajah.HusseinAICounter`.

## What's new in 2.0

- Actual `VNDetectFaceRectanglesRequest` face boxes instead of suggesting person-body detections are head locations. Detected faces appear as **solid teal boxes**. People seen without a detectable face appear as **dashed amber BODY boxes**, not fabricated head boxes.
- Combine face + upper-body human requests; match face-to-person and avoid counting a matched face twice.
- Stable face/body tracks: smoothing, two-frame confirmation and brief tolerance for missed frames to reduce jitter and count oscillation. This is *not* facial identity recognition and **not** guaranteed unique-person attendance across a moving scan.
- The video overlay maps normalized boxes onto the same fitted/filled preview image rectangle, accounting for the camera panel aspect ratio. The live video buffer is requested in portrait orientation; app orientation is portrait.
- Real optical camera choice **0.5× ultrawide** (when hardware permits) and **1× main camera**, plus digital zoom, torch on supported devices, and tap-to-focus/expose.
- Automatic local count snapshots after **6 seconds of stable, nonzero count**, with cooldown and deduplication. Manual save is retained. Still-photo and photo-library counts are also saved locally.
- Optional lecture name attached to future count records, while retaining compatibility with stored v1 data.
- Seven-day statistics chart, overall max, average, records today, CSV sharing and clear-history controls.
- Optional small sound and haptic feedback when saving; off by default for sound.
- Calm dark-blue/teal UI, adjustable camera preview size, fit/fill, original Arabic labels and original copyright footer.

## IMPORTANT limitations

1. An actual face detector only finds **visible faces**. A student with a turned/hidden face gets an amber person box **only if** the human detector can see enough body. Students behind other people, outside the camera view, or distant in poor light may be missed.
2. **0.5× shows more of the room but makes people smaller**, potentially reducing detection accuracy. For best results, test 0.5× and 1× at the same distance and avoid extreme backlighting.
3. “Count” is the number of currently visible detections, **not** the cumulative number of unique people seen while panning. Do not use it as authoritative attendance without manual verification.
4. The exact alignment and counting quality need **real device testing**. Code was checked for Swift parse, plist/project structure and image identity on Linux. **No Xcode/iOS SDK compile or physical-device QA was possible here.** GitHub Actions will run the first actual build and must succeed before using the IPA.
5. Photos and camera frames are analysed on-device with Apple Vision; the auto-history stores count, source, lecture title and date/time, not student pictures or facial identities.

## Source layout

- `HusseinAICounter.xcodeproj` — iOS app Xcode project / scheme
- `HusseinAICounter/CameraCounter.swift` — AVFoundation, device lens management, face/body detection and tracking
- `HusseinAICounter/HomeView.swift` — native SwiftUI UI, live preview, photos, stats and history
- `HusseinAICounter/CountingHistory.swift` — v1-compatible local persistence and CSV
- `HusseinAICounter/SplashView.swift` — unchanged gentle intro
- `HusseinAICounter/Assets.xcassets` — original unchanged icon/launch artwork
- `HusseinAICounter/Info.plist` — camera/photo permissions + corrected CFBundleIdentifier
- `.github/workflows/build-ipa.yml` — macOS Xcode build, compiled-app validation and unsigned IPA upload
- `tests/validate_release.py` — offline source and asset integrity checks
- `INSTALL-WINDOWS-AR.md` — Arabic Windows → GitHub → Sideloadly installation / upgrade steps

## Build and install

See **[INSTALL-WINDOWS-AR.md](INSTALL-WINDOWS-AR.md)**. Produces an **unsigned IPA** which Sideloadly must sign. **You cannot install the source ZIP directly on an iPhone.**
