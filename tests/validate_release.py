"""Offline project-structure smoke checks; does not replace Xcode/device tests."""
from pathlib import Path
import plistlib
import hashlib
import re

root = Path(__file__).resolve().parents[1]
app = root / "HusseinAICounter"
info = plistlib.loads((app / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "$(PRODUCT_BUNDLE_IDENTIFIER)"
assert "NSCameraUsageDescription" in info
assert "NSPhotoLibraryUsageDescription" in info
assert "CFBundleShortVersionString" in info
assert "CFBundleExecutable" in info

project = (root / "HusseinAICounter.xcodeproj/project.pbxproj").read_text()
for file in ["HusseinAICounterApp.swift", "HomeView.swift", "CameraCounter.swift", "CountingHistory.swift", "SplashView.swift"]:
    assert (app / file).is_file(), file
    assert file in project, f"Missing Xcode reference to {file}"
assert "MARKETING_VERSION = 2.0;" in project
assert "CURRENT_PROJECT_VERSION = 3;" in project
assert "PRODUCT_BUNDLE_IDENTIFIER = com.husseinnajah.HusseinAICounter;" in project

icon = (app / "Assets.xcassets/AppIcon.appiconset/AppIcon.png").read_bytes()
splash = (app / "Assets.xcassets/LaunchMonogram.imageset/LaunchMonogram.png").read_bytes()
assert icon == splash, "The HN icon and splash monogram must stay identical"
assert hashlib.sha256(icon).hexdigest() == "4eee24c19e219864a95bb2e39e835ccc8b41f3957a6a0fbfd0a1b27d668cc2b6", "The user's original icon must not change"

source = (app / "CameraCounter.swift").read_text()
for token in ["VNDetectFaceRectanglesRequest", "VNDetectHumanRectanglesRequest", "builtInUltraWideCamera", "BoxTracker", "setTorch"]:
    assert token in source, token
assert "builtInUltraWideAngleCamera" not in source, "Invalid AVFoundation ultra-wide camera constant"

print("PASS: source and asset checks; original HN artwork unchanged; signed build still requires macOS")
