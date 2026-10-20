import Foundation
import AVFoundation
import Vision
import UIKit
import ImageIO
import Combine

// Vision's rectangles are normalized (0...1), origin at the BOTTOM LEFT.
// We never pretend an estimated person rectangle is a detected face/head.
enum DetectionKind: String {
    case face
    case person
}

struct DetectionBox: Identifiable {
    let id: Int
    var rect: CGRect
    let kind: DetectionKind
}

struct DetectionResult {
    let boxes: [DetectionBox]
    var count: Int { boxes.count }
    var faceCount: Int { boxes.filter { $0.kind == .face }.count }
}

struct CapturedCount: Identifiable {
    let id = UUID()
    let image: UIImage
    let boxes: [DetectionBox]
    var count: Int { boxes.count }
}

enum CameraLens: String, CaseIterable {
    case wide
    case ultraWide
    var label: String { self == .wide ? "1×" : "0.5×" }
}

/// Detects REAL face rectangles and human rectangles independently.
/// Faces are paired with their corresponding bodies to avoid counting twice.
/// An undetected face is NOT replaced with an invented little head box.
enum PeopleDetector {
    static func detect(_ handler: VNImageRequestHandler) throws -> DetectionResult {
        let faceRequest = VNDetectFaceRectanglesRequest()
        let humanRequest = VNDetectHumanRectanglesRequest()
        // Upper-body mode helps with seated or partially visible students.
        humanRequest.upperBodyOnly = true
        try handler.perform([faceRequest, humanRequest])

        let faces = suppressOverlaps((faceRequest.results ?? [])
            .filter { $0.confidence >= 0.30 }
            .map(\.boundingBox))
        let humans = suppressOverlaps((humanRequest.results ?? [])
            .filter { $0.confidence >= 0.30 }
            .map(\.boundingBox))

        var matchedFaces = Set<Int>()
        var output: [DetectionBox] = []
        for human in humans {
            // Pair a face with a body ONLY if the face center lies near the upper region.
            let upperRegion = CGRect(x: human.minX - human.width * 0.12,
                                     y: human.minY + human.height * 0.40,
                                     width: human.width * 1.24,
                                     height: human.height * 0.75)
            let candidate = faces.indices
                .filter { !matchedFaces.contains($0) && upperRegion.contains(CGPoint(x: faces[$0].midX, y: faces[$0].midY)) }
                .min { abs(faces[$0].midX - human.midX) < abs(faces[$1].midX - human.midX) }
            if let candidate {
                matchedFaces.insert(candidate)
                output.append(DetectionBox(id: output.count, rect: faces[candidate], kind: .face))
            } else {
                output.append(DetectionBox(id: output.count, rect: human, kind: .person))
            }
        }
        for index in faces.indices where !matchedFaces.contains(index) {
            output.append(DetectionBox(id: output.count, rect: faces[index], kind: .face))
        }
        // Make ordering deterministic for repeatability and tracking.
        output.sort { $0.rect.midX < $1.rect.midX }
        return DetectionResult(boxes: output.enumerated().map {
            DetectionBox(id: $0.offset, rect: $0.element.rect, kind: $0.element.kind)
        })
    }

    private static func suppressOverlaps(_ rects: [CGRect]) -> [CGRect] {
        var kept: [CGRect] = []
        for candidate in rects.sorted(by: { $0.width * $0.height > $1.width * $1.height }) {
            if !kept.contains(where: { overlap($0, candidate) > 0.58 }) { kept.append(candidate) }
        }
        return kept
    }

    static func overlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let areaA = a.width * a.height
        let areaB = b.width * b.height
        return (intersection.width * intersection.height) / max(0.00001, areaA + areaB - intersection.width * intersection.height)
    }
}

/// A lightweight temporal tracker: smoothing positions + keeping identities for
/// a couple of missed frames. This is stability, not identity recognition.
private final class BoxTracker {
    private struct Track {
        var id: Int
        var rect: CGRect
        var kind: DetectionKind
        var hits: Int
        var misses: Int
    }
    private var tracks: [Track] = []
    private var nextID = 0

    func reset() { tracks.removeAll(); nextID = 0 }

    func update(_ incoming: [DetectionBox]) -> [DetectionBox] {
        for index in tracks.indices { tracks[index].misses += 1 }
        var reserved = Set<Int>()
        for item in incoming {
            let point = CGPoint(x: item.rect.midX, y: item.rect.midY)
            let candidates = tracks.indices.filter { !reserved.contains($0) }
            let best = candidates.map { index -> (Int, CGFloat) in
                let old = tracks[index].rect
                if tracks[index].kind != item.kind {
                    // A person turning towards/away from the camera may switch
                    // between face and body observations; keep ONE identity.
                    let face = item.kind == .face ? item.rect : old
                    let person = item.kind == .person ? item.rect : old
                    let upper = CGRect(x: person.minX - person.width * 0.1,
                                       y: person.midY, width: person.width * 1.2,
                                       height: person.height * 0.65)
                    let faceCenter = CGPoint(x: face.midX, y: face.midY)
                    return (index, upper.contains(faceCenter) ? 0.33 : 0)
                }
                let score = PeopleDetector.overlap(old, item.rect)
                let dx = (old.midX - point.x)
                let dy = (old.midY - point.y)
                let distance = sqrt(dx * dx + dy * dy)
                let distanceScore = max(0, 1 - distance / max(0.12, max(old.width, item.rect.width)))
                return (index, max(score, distanceScore * 0.48))
            }.max { $0.1 < $1.1 }

            if let best, best.1 > 0.22 {
                reserved.insert(best.0)
                let sameKind = tracks[best.0].kind == item.kind
                tracks[best.0].rect = sameKind ? smooth(tracks[best.0].rect, item.rect, amount: 0.56) : item.rect
                tracks[best.0].kind = item.kind
                tracks[best.0].hits += 1
                tracks[best.0].misses = 0
            } else {
                let index = tracks.count
                tracks.append(Track(id: nextID, rect: item.rect, kind: item.kind, hits: 1, misses: 0))
                nextID += 1
                reserved.insert(index)
            }
        }
        // Briefly tolerate missed detections, but avoid counting stale people.
        tracks.removeAll { $0.misses > 2 }
        return tracks.filter { $0.hits >= 2 && $0.misses <= 1 }.map {
            DetectionBox(id: $0.id, rect: $0.rect, kind: $0.kind)
        }
    }

    private func smooth(_ a: CGRect, _ b: CGRect, amount: CGFloat) -> CGRect {
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * amount }
        return CGRect(x: mix(a.minX, b.minX), y: mix(a.minY, b.minY),
                      width: mix(a.width, b.width), height: mix(a.height, b.height))
    }
}

/// All camera session mutations use sessionQueue, all Vision/tracking work uses
/// visionQueue, and all published UI properties are changed on the main queue.
final class CameraCounter: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    @Published private(set) var boxes: [DetectionBox] = []
    @Published private(set) var count = 0
    @Published private(set) var facesDetected = 0
    @Published private(set) var isRunning = false
    @Published var errorMessage: String?
    @Published var capture: CapturedCount?
    @Published private(set) var zoomFactor: CGFloat = 1
    @Published private(set) var maxZoomFactor: CGFloat = 5
    @Published private(set) var selectedLens: CameraLens = .wide
    @Published private(set) var torchEnabled = false
    @Published private(set) var supportsTorch = false
    @Published private(set) var videoAspectRatio: CGFloat = 9.0 / 16.0

    let supportsUltraWide: Bool = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInUltraWideAngleCamera], mediaType: .video, position: .back
    ).devices.first != nil

    private let sessionQueue = DispatchQueue(label: "hn.camera.session")
    private let visionQueue = DispatchQueue(label: "hn.camera.vision", qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private let frameOutput = AVCaptureVideoDataOutput()
    private let tracker = BoxTracker()
    private var input: AVCaptureDeviceInput?
    private var isConfigured = false
    private var lastDetectionTime: CFTimeInterval = 0

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] permitted in
                if permitted { self?.configureAndStart() }
                else { DispatchQueue.main.async { self?.errorMessage = "يرجى السماح للتطبيق باستخدام الكاميرا من الإعدادات." } }
            }
        default:
            DispatchQueue.main.async { self.errorMessage = "الوصول إلى الكاميرا مرفوض. فعّل الإذن من إعدادات الآيفون." }
        }
    }

    private func chosenDevice(for lens: CameraLens) -> AVCaptureDevice? {
        if lens == .ultraWide {
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideAngleCamera],
                   mediaType: .video, position: .back).devices.first
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.session.beginConfiguration()
                // .photo preserves capture detail; Vision processing is throttled.
                self.session.sessionPreset = .photo
                guard let device = self.chosenDevice(for: .wide),
                      let newInput = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(newInput) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.errorMessage = "تعذر إعداد الكاميرا الخلفية." }
                    return
                }
                self.session.addInput(newInput)
                self.input = newInput
                self.frameOutput.alwaysDiscardsLateVideoFrames = true
                self.frameOutput.setSampleBufferDelegate(self, queue: self.visionQueue)
                guard self.session.canAddOutput(self.frameOutput), self.session.canAddOutput(self.photoOutput) else {
                    self.session.removeInput(newInput)
                    self.input = nil
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.errorMessage = "تعذر إعداد الكاميرا الخلفية." }
                    return
                }
                self.session.addOutput(self.frameOutput)
                self.session.addOutput(self.photoOutput)
                self.configurePhotoQuality(for: device)
                self.session.commitConfiguration()
                self.isConfigured = true
                // Portrait buffers give Vision a consistent, upright coordinate
                // space. Preview orientation is also set to portrait in PreviewView.
                if let connection = self.frameOutput.connection(with: .video), connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                self.publishDeviceState(device, lens: .wide)
            }
            if !self.session.isRunning { self.session.startRunning() }
            DispatchQueue.main.async {
                self.isRunning = self.session.isRunning
                if self.isRunning { self.errorMessage = nil }
            }
        }
    }

    private func configurePhotoQuality(for device: AVCaptureDevice) {
        photoOutput.maxPhotoQualityPrioritization = .quality
        if let highest = device.activeFormat.supportedMaxPhotoDimensions.max(by: {
            Int($0.width) * Int($0.height) < Int($1.width) * Int($1.height)
        }) { photoOutput.maxPhotoDimensions = highest }
    }

    private func publishDeviceState(_ device: AVCaptureDevice, lens: CameraLens) {
        DispatchQueue.main.async {
            self.selectedLens = lens
            self.zoomFactor = 1
            self.maxZoomFactor = max(1, min(device.activeFormat.videoMaxZoomFactor, 5))
            self.supportsTorch = device.hasTorch
            self.torchEnabled = false
            self.boxes = []
            self.count = 0
            self.facesDetected = 0
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let device = self.input?.device, device.hasTorch,
               (try? device.lockForConfiguration()) != nil {
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            if self.session.isRunning { self.session.stopRunning() }
            self.visionQueue.async { self.tracker.reset(); self.lastDetectionTime = 0 }
            DispatchQueue.main.async {
                self.isRunning = false
                self.boxes = []
                self.count = 0
                self.facesDetected = 0
                self.torchEnabled = false
            }
        }
    }

    func setLens(_ lens: CameraLens) {
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured,
                  let device = self.chosenDevice(for: lens),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }
            if self.input?.device.uniqueID == device.uniqueID { return }
            self.session.beginConfiguration()
            let old = self.input
            if let old { self.session.removeInput(old) }
            guard self.session.canAddInput(newInput) else {
                if let old { self.session.addInput(old) }
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.errorMessage = "تعذر تغيير عدسة الكاميرا." }
                return
            }
            self.session.addInput(newInput)
            self.input = newInput
            self.configurePhotoQuality(for: device)
            self.session.commitConfiguration()
            self.visionQueue.async { self.tracker.reset(); self.lastDetectionTime = 0 }
            self.publishDeviceState(device, lens: lens)
        }
    }

    func setZoom(_ requested: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.input?.device else { return }
            let value = min(max(requested, 1), min(device.activeFormat.videoMaxZoomFactor, 5))
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: value, withRate: 7)
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.zoomFactor = value }
            } catch { DispatchQueue.main.async { self.errorMessage = "تعذر تغيير تقريب الكاميرا." } }
        }
    }

    func setTorch(_ requested: Bool) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.input?.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = requested ? .on : .off
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.torchEnabled = requested }
            } catch { DispatchQueue.main.async { self.errorMessage = "تعذر تشغيل الإضاءة." } }
        }
    }

    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.input?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch { /* Tap-to-focus is optional on certain hardware. */ }
        }
    }

    func takePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            let dims = self.photoOutput.maxPhotoDimensions
            if dims.width > 0 && dims.height > 0 { settings.maxPhotoDimensions = dims }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastDetectionTime >= 0.42,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastDetectionTime = now
        // Portrait output rotation above -> Vision .up. Fallback for other
        // capture connections is .right (native sensor landscape buffers).
        let upright = connection.isVideoOrientationSupported && connection.videoOrientation == .portrait
        let orientation: CGImagePropertyOrientation = upright ? .up : .right
        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        let aspect = upright ? width / max(1, height) : height / max(1, width)
        do {
            let result = try PeopleDetector.detect(VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation))
            let stableBoxes = tracker.update(result.boxes)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning else { return }
                self.boxes = stableBoxes
                self.count = stableBoxes.count
                self.facesDetected = stableBoxes.filter { $0.kind == .face }.count
                self.videoAspectRatio = aspect
            }
        } catch { /* Retain previous count on an occasional invalid frame. */ }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in self?.errorMessage = "تعذر التقاط الصورة." }
            return
        }
        visionQueue.async { [weak self] in
            let result = PhotoDetector.detect(in: image)
            DispatchQueue.main.async { self?.capture = CapturedCount(image: image, boxes: result.boxes) }
        }
    }
}

enum PhotoDetector {
    static func detect(in image: UIImage) -> DetectionResult {
        guard let cgImage = image.cgImage else { return DetectionResult(boxes: []) }
        do { return try PeopleDetector.detect(VNImageRequestHandler(cgImage: cgImage, orientation: image.cgOrientation)) }
        catch { return DetectionResult(boxes: []) }
    }
}

extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
