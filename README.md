# Hussein AI Counter — Native iOS 1.1

**Designed By Hussein Najah**

An original SwiftUI iOS app for locally counting visible people in a classroom via Apple Vision, with live camera, still-photo capture, Photos picker, saved count history, CSV sharing, new professional HN icon and gentle animated intro. Preserves original user-facing copy.

## For Windows users

Follow [INSTALL-WINDOWS-AR.md](INSTALL-WINDOWS-AR.md) (Arabic). GitHub Actions compiles an **unsigned IPA** on a hosted Mac. Sideloadly signs and installs it on iPhone with a supported Apple account. The ZIP is a buildable project, **not** a pre-signed installable IPA.

## Source layout

- `HusseinAICounter.xcodeproj` — Xcode project & shareable scheme
- `HusseinAICounter/HusseinAICounterApp.swift` — app entry
- `HusseinAICounter/SplashView.swift` — minimal zoom/fade welcome screen
- `HusseinAICounter/HomeView.swift` — calm main UI; camera panel size/zoom and fit/fill control
- `HusseinAICounter/CameraCounter.swift` — camera setup and Vision analysis
- `HusseinAICounter/CountingHistory.swift` — local persistence and CSV export
- `HusseinAICounter/Assets.xcassets` — icon + launch branding
- `.github/workflows/build-ipa.yml` — produces an unsigned IPA artifact

Deployment target: iOS 17.0+. Privacy: camera and selected photos processed on-device.

**Note:** The project has been statically validated, but an actual iOS SDK compile, signing and device test are still required.
