"""Static release checks for Student AI Counter 3.0 (not an Xcode compile)."""
from pathlib import Path
import plistlib
import struct

root = Path(__file__).resolve().parents[1]
app = root / 'HusseinAICounter'
project = (root / 'HusseinAICounter.xcodeproj/project.pbxproj').read_text(encoding='utf8')
with (app / 'Info.plist').open('rb') as f:
    info = plistlib.load(f)
assert info['CFBundleDisplayName'] == 'Student AI Counter'
assert info['CFBundleIdentifier'] == '$(PRODUCT_BUNDLE_IDENTIFIER)'
assert 'NSCameraUsageDescription' in info
assert 'NSPhotoLibraryUsageDescription' in info
for filename in ['HusseinAICounterApp.swift', 'HomeView.swift', 'CameraCounter.swift', 'SplashView.swift', 'CountingHistory.swift', 'AppTheme.swift']:
    assert (app / filename).is_file(), filename
    assert filename in project, f'Project reference missing: {filename}'
assert 'MARKETING_VERSION = 3.0;' in project
assert 'CURRENT_PROJECT_VERSION = 4;' in project
assert 'PRODUCT_BUNDLE_IDENTIFIER = com.husseinnajah.HusseinAICounter;' in project
icon = app / 'Assets.xcassets/AppIcon.appiconset/AppIcon.png'
gate = app / 'Assets.xcassets/GoldenGate.imageset/GoldenGate.png'
def png_dimensions(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    return struct.unpack('>II', data[16:24]), data[25]
assert png_dimensions(icon) == ((1024, 1024), 2), 'App icon must be opaque RGB 1024px PNG'
assert png_dimensions(gate)[0] == (1024, 1024)
source = (app / 'CameraCounter.swift').read_text()
for token in ['VNDetectFaceRectanglesRequest', 'VNDetectHumanRectanglesRequest',
              'builtInUltraWideCamera', 'flipCamera()', 'adjustZoom(by', 'BoxTracker']:
    assert token in source, token
assert 'builtInUltraWideAngleCamera' not in source
ui = (app / 'HomeView.swift').read_text()
for token in ['CameraPreview', 'StatisticsScreen', 'HistoryScreen', 'SettingsScreen',
              'PhotosPicker', 'UIPinchGestureRecognizer', 'GoldenGate']:
    assert token in ui, token
assert 'hn.camera.previewHeight' not in ui
assert 'GoldenGate' in (app / 'SplashView.swift').read_text()
assert 'Designed By Hussein Najah' in (app / 'AppTheme.swift').read_text()
assert 'HusseinAICounter.CountingHistory.v1' in (app / 'CountingHistory.swift').read_text()
print('PASS: static project structure, icon, splash, metadata, privacy, migration, feature checks')
