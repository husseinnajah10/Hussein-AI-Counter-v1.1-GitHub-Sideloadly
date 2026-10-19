import Foundation
import AVFoundation
import Vision
import UIKit
import ImageIO
import Combine

struct CapturedCount: Identifiable {
    let id = UUID()
    let image: UIImage
    let rectangles: [CGRect]
}

/// Vision analysis takes place on-device; no camera frames are uploaded.
final class CameraCounter: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    @Published var rectangles: [CGRect] = []
    @Published var count = 0
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var capture: CapturedCount?
    @Published private(set) var zoomFactor: CGFloat = 1
    @Published private(set) var maxZoomFactor: CGFloat = 5

    private let sessionQueue = DispatchQueue(label: "hn.camera.session")
    private let visionQueue = DispatchQueue(label: "hn.camera.vision", qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private var cameraDevice: AVCaptureDevice?
    private var isConfigured = false
    private var lastDetectionTime: CFTimeInterval = 0
    private let detectionRequest = VNDetectHumanRectanglesRequest()

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureAndStart()
                } else {
                    DispatchQueue.main.async { self?.errorMessage = "يرجى السماح للتطبيق باستخدام الكاميرا من الإعدادات." }
                }
            }
        default:
            DispatchQueue.main.async {
                self.errorMessage = "الوصول إلى الكاميرا مرفوض. فعّل الإذن من إعدادات الآيفون."
            }
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.session.beginConfiguration()
                // .photo gives still photography priority; the video stream remains
                // independently throttled so Vision cannot block the preview.
                self.session.sessionPreset = .photo
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.errorMessage = "تعذر إعداد الكاميرا الخلفية." }
                    return
                }
                self.cameraDevice = device
                self.session.addInput(input)

                let frames = AVCaptureVideoDataOutput()
                frames.alwaysDiscardsLateVideoFrames = true
                frames.setSampleBufferDelegate(self, queue: self.visionQueue)
                guard self.session.canAddOutput(frames), self.session.canAddOutput(self.photoOutput) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.errorMessage = "تعذر إعداد الكاميرا الخلفية." }
                    return
                }
                self.session.addOutput(frames)
                self.session.addOutput(self.photoOutput)
                // Set photography quality before startRunning() to avoid pipeline resets.
                self.photoOutput.maxPhotoQualityPrioritization = .quality
                if let largest = device.activeFormat.supportedMaxPhotoDimensions.max(by: {
                    Int($0.width) * Int($0.height) < Int($1.width) * Int($1.height)
                }) {
                    self.photoOutput.maxPhotoDimensions = largest
                }
                self.session.commitConfiguration()
                self.isConfigured = true
                let maximum = min(device.activeFormat.videoMaxZoomFactor, 5)
                DispatchQueue.main.async { self.maxZoomFactor = max(1, maximum) }
            }
            if !self.session.isRunning { self.session.startRunning() }
            DispatchQueue.main.async {
                self.isRunning = self.session.isRunning
                self.errorMessage = nil
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async {
                self.isRunning = false
                self.rectangles = []
                self.count = 0
            }
        }
    }

    func setZoom(_ requested: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.cameraDevice else { return }
            let value = min(max(requested, 1), min(device.activeFormat.videoMaxZoomFactor, 5))
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: value, withRate: 8)
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.zoomFactor = value }
            } catch {
                DispatchQueue.main.async { self.errorMessage = "تعذر إعداد الكاميرا الخلفية." }
            }
        }
    }

    func takePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            let supportedDimensions = self.photoOutput.maxPhotoDimensions
            if supportedDimensions.width > 0 && supportedDimensions.height > 0 {
                settings.maxPhotoDimensions = supportedDimensions
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastDetectionTime >= 0.38,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastDetectionTime = now

        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right).perform([detectionRequest])
            let found = (detectionRequest.results ?? []).map(\.boundingBox)
            DispatchQueue.main.async { [weak self] in
                guard self?.isRunning == true else { return }
                self?.rectangles = found
                self?.count = found.count
            }
        } catch {
            // Keep the previous valid count if a frame fails.
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in self?.errorMessage = "تعذر التقاط الصورة." }
            return
        }
        visionQueue.async { [weak self] in
            let found = PhotoDetector.detect(in: image)
            DispatchQueue.main.async { self?.capture = CapturedCount(image: image, rectangles: found) }
        }
    }
}

/// Vision boxes are normalized [0,1], origin at the bottom-left.
enum PhotoDetector {
    static func detect(in image: UIImage) -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        do {
            try VNImageRequestHandler(cgImage: cgImage, orientation: image.cgOrientation).perform([request])
            return (request.results ?? []).map(\.boundingBox)
        } catch { return [] }
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
