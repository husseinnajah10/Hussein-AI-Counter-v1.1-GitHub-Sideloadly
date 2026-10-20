import SwiftUI
import AVFoundation
import PhotosUI
import AudioToolbox
import Charts
import UniformTypeIdentifiers

// The original public-facing texts and the HN identity remain in place.
enum CalmColors {
    static let accent = Color(red: 0.37, green: 0.70, blue: 0.76)
    static let background = Color(red: 0.055, green: 0.095, blue: 0.134)
    static let panel = Color(red: 0.105, green: 0.157, blue: 0.197)
    static let soft = Color(red: 0.17, green: 0.27, blue: 0.32)
}

enum GentleFeedback {
    static func completed(playsSound: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if playsSound { AudioServicesPlaySystemSound(1104) }
    }
}

struct HomeView: View {
    @StateObject private var camera = CameraCounter()

    var body: some View {
        TabView {
            NavigationStack { LiveCountView(camera: camera) }
                .tabItem { Label("الكاميرا", systemImage: "camera.viewfinder") }
            NavigationStack { PhotoCountView() }
                .tabItem { Label("الصور", systemImage: "photo.on.rectangle") }
            NavigationStack { StatisticsView() }
                .tabItem { Label("الإحصائيات", systemImage: "chart.bar.xaxis") }
            NavigationStack { HistoryView() }
                .tabItem { Label("السجل", systemImage: "list.bullet.rectangle") }
        }
        .tint(CalmColors.accent)
        .background(CalmColors.background.ignoresSafeArea())
    }
}

private struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hussein AI Counter")
                .font(.title2.bold()).foregroundStyle(.white)
            Text("عدّ الأشخاص داخل القاعة باستخدام الذكاء الاصطناعي")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TotalCard: View {
    let count: Int?
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Text(label).font(.subheadline).foregroundStyle(.white.opacity(0.80))
            Text(count.map { String($0) } ?? "—")
                .font(.system(size: 74, weight: .bold, design: .rounded))
                .monospacedDigit().contentTransition(.numericText())
                .foregroundStyle(.white)
            Text("شخصاً تم اكتشافه")
                .font(.footnote).foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            LinearGradient(colors: [CalmColors.soft, CalmColors.panel],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}

struct LiveCountView: View {
    @ObservedObject var camera: CameraCounter
    @EnvironmentObject private var history: CountingHistory
    @AppStorage("hn.camera.previewHeight") private var previewHeight: Double = 365
    @AppStorage("hn.camera.showCompleteFrame") private var showsCompleteFrame = true
    @AppStorage("hn.autoRecord") private var autoRecord = true
    @AppStorage("hn.playSounds") private var playSounds = false
    @AppStorage("hn.lectureName") private var lectureName = ""
    @State private var feedback: String?
    @State private var requestedZoom: Double = 1
    @State private var autoSaveTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandHeader()
                TotalCard(count: camera.isRunning ? camera.count : nil, label: "العد المباشر")
                CameraPreview(session: camera.session,
                              boxes: camera.boxes,
                              videoAspectRatio: camera.videoAspectRatio,
                              showsCompleteFrame: showsCompleteFrame,
                              onFocus: { camera.focus(at: $0) })
                    .frame(height: previewHeight)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 20))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .topLeading) {
                        Label(camera.isRunning ? "LIVE" : "OFF", systemImage: "circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(camera.isRunning ? .mint : .secondary)
                            .padding(8)
                            .background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 8))
                            .padding(12)
                    }
                    .overlay(alignment: .bottom) {
                        if camera.isRunning {
                            HStack(spacing: 10) {
                                Label("وجه: \(camera.facesDetected)", systemImage: "face.smiling")
                                Label("شخص: \(max(0, camera.count - camera.facesDetected))", systemImage: "person.crop.rectangle")
                            }
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .foregroundStyle(.white)
                            .background(.black.opacity(0.70), in: Capsule())
                            .padding(10)
                        }
                    }
                Text("الإطار الأزرق للوجه المكتشف، والإطار المتقطع للشخص الذي لم يظهر وجهه بوضوح.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Label("العدسة", systemImage: "camera.aperture").font(.subheadline.bold())
                        Spacer()
                        if camera.supportsUltraWide {
                            Button("0.5×") { switchLens(.ultraWide) }
                                .buttonStyle(.bordered)
                                .tint(camera.selectedLens == .ultraWide ? CalmColors.accent : .gray)
                                .accessibilityLabel("العدسة الواسعة جداً نصف إكس")
                        }
                        Button("1×") { switchLens(.wide) }
                            .buttonStyle(.bordered)
                            .tint(camera.selectedLens == .wide ? CalmColors.accent : .gray)
                        Button {
                            camera.setTorch(!camera.torchEnabled)
                        } label: {
                            Image(systemName: camera.torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!camera.isRunning || !camera.supportsTorch)
                        .accessibilityLabel("تشغيل أو إيقاف ضوء الكاميرا")
                    }
                    if camera.supportsUltraWide {
                        Text("عدسة 0.5× الحقيقية لعرض مساحة أوسع من القاعة.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("حجم شاشة الكاميرا", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text("\(Int(previewHeight))").font(.footnote.monospacedDigit())
                    }
                    Slider(value: $previewHeight, in: 240...560, step: 10)
                        .accessibilityLabel("حجم شاشة الكاميرا")
                    Toggle("عرض إطار الكاميرا بالكامل", isOn: $showsCompleteFrame)
                        .font(.footnote)
                    HStack {
                        Label("تقريب الكاميرا", systemImage: "plus.magnifyingglass")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text(String(format: "%.1f×", requestedZoom))
                            .font(.footnote.monospacedDigit())
                    }
                    Slider(value: $requestedZoom,
                           in: 1...max(Double(camera.maxZoomFactor), 1.01), step: 0.1)
                        .disabled(!camera.isRunning)
                        .onChange(of: requestedZoom) { _, value in camera.setZoom(CGFloat(value)) }
                    Text("اضغط على مكان داخل الكاميرا لضبط التركيز والإضاءة عليه.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(14)
                .background(CalmColors.panel, in: RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 10) {
                    Button {
                        camera.isRunning ? camera.stop() : camera.start()
                    } label: {
                        Label(camera.isRunning ? "إيقاف" : "تشغيل",
                              systemImage: camera.isRunning ? "stop.fill" : "video.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(camera.isRunning ? .red : CalmColors.accent)
                    Button { camera.takePhoto() } label: {
                        Label("التقاط", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!camera.isRunning)
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    TextField("اسم المحاضرة (اختياري)", text: $lectureName)
                        .textInputAutocapitalization(.never)
                        .padding(10)
                        .background(CalmColors.background, in: RoundedRectangle(cornerRadius: 10))
                    Toggle("الحفظ التلقائي للعدد المستقر", isOn: $autoRecord)
                        .onChange(of: autoRecord) { _, enabled in
                            if !enabled { autoSaveTask?.cancel() }
                            else { scheduleAutoSave(camera.count) }
                        }
                    Toggle("أصوات وتنبيهات خفيفة", isOn: $playSounds)
                    Text("يحفظ النتيجة بعد ثبات العدد حوالي 6 ثوانٍ، مع منع الحفظ المتكرر سريعاً. بدون تخزين صور الطلاب.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(14)
                .background(CalmColors.panel, in: RoundedRectangle(cornerRadius: 18))

                Button {
                    guard camera.isRunning else { return }
                    history.add(camera.count, mode: "مباشر", lectureTitle: lectureName)
                    feedback = "تم حفظ العدد: \(camera.count)"
                    GentleFeedback.completed(playsSound: playSounds)
                } label: {
                    Label("حفظ العدد الحالي", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!camera.isRunning)
                if let feedback { Text(feedback).foregroundStyle(.mint).font(.footnote) }
                Text("يعرض عدد الأشخاص الظاهرين فقط. قد لا يكتشف الأشخاص المحجوبين أو الموجودين خارج إطار الكاميرا.")
                    .font(.footnote).foregroundStyle(.secondary)
                CopyrightFooter()
            }
            .padding(18)
        }
        .background(CalmColors.background)
        .navigationTitle("الكاميرا المباشرة")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { camera.start() }
        .onDisappear { autoSaveTask?.cancel(); camera.stop() }
        .onChange(of: camera.count) { _, newValue in scheduleAutoSave(newValue) }
        .onChange(of: camera.zoomFactor) { _, newZoom in requestedZoom = Double(newZoom) }
        .alert("مشكلة في الكاميرا", isPresented: Binding(
            get: { camera.errorMessage != nil },
            set: { if !$0 { camera.errorMessage = nil } }
        )) {
            Button("حسناً", role: .cancel) { camera.errorMessage = nil }
        } message: { Text(camera.errorMessage ?? "") }
        .onChange(of: camera.capture?.id) { _, _ in
            guard let result = camera.capture else { return }
            history.add(result.count, mode: "التقاط صورة", lectureTitle: lectureName)
            GentleFeedback.completed(playsSound: playSounds)
        }
        .sheet(item: $camera.capture) { result in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        TotalCard(count: result.count, label: "نتيجة الصورة الملتقطة")
                        DetectedImage(image: result.image, boxes: result.boxes)
                        Text("الإطار الأزرق للوجوه، والذهبي المتقطع للأشخاص دون وجه واضح.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("حفظ هذا العدد") {
                            history.add(result.count, mode: "التقاط صورة", lectureTitle: lectureName)
                            GentleFeedback.completed(playsSound: playSounds)
                            camera.capture = nil
                        }
                        .buttonStyle(.borderedProminent).tint(CalmColors.accent)
                    }
                    .padding()
                }
                .background(CalmColors.background)
                .navigationTitle("الصورة الملتقطة")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("إغلاق") { camera.capture = nil }
                    }
                }
            }
        }
    }

    private func switchLens(_ lens: CameraLens) {
        requestedZoom = 1
        camera.setLens(lens)
    }

    private func scheduleAutoSave(_ newCount: Int) {
        autoSaveTask?.cancel()
        guard autoRecord, camera.isRunning, newCount > 0 else { return }
        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            while !Task.isCancelled, autoRecord, camera.isRunning, camera.count == newCount {
                if history.addAutoSnapshot(newCount, lectureTitle: lectureName) {
                    feedback = "حُفظ تلقائياً: \(newCount)"
                    GentleFeedback.completed(playsSound: playSounds)
                }
                // Retry after the minimum log interval if a previous auto-save
                // was suppressed by deduplication/cooldown.
                try? await Task.sleep(nanoseconds: 20_000_000_000)
            }
        }
    }
}

struct PhotoCountView: View {
    @EnvironmentObject private var history: CountingHistory
    @AppStorage("hn.playSounds") private var playSounds = false
    @AppStorage("hn.lectureName") private var lectureName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var boxes: [DetectionBox] = []
    @State private var analyzing = false
    @State private var analyzed = false
    @State private var feedback: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandHeader()
                TotalCard(count: analyzed ? boxes.count : nil, label: "تحليل صورة")
                if let image {
                    DetectedImage(image: image, boxes: boxes)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.055))
                        .frame(height: 330)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                Text("اختر صورة للقاعة لتحليلها").font(.headline)
                            }.foregroundStyle(.secondary)
                        }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("اختيار صورة من الجهاز", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CalmColors.accent)
                .controlSize(.large)
                .onChange(of: selectedPhoto) { _, item in
                    guard let item else { return }
                    analyzing = true
                    analyzed = false
                    feedback = nil
                    Task {
                        do {
                            guard let data = try await item.loadTransferable(type: Data.self),
                                  let picture = UIImage(data: data) else {
                                feedback = "تعذر قراءة الصورة"; analyzing = false; return
                            }
                            let result = await Task.detached(priority: .userInitiated) {
                                PhotoDetector.detect(in: picture)
                            }.value
                            image = picture
                            boxes = result.boxes
                            analyzed = true
                            history.add(result.count, mode: "صورة من الألبوم", lectureTitle: lectureName)
                            feedback = "تم حفظ العدد: \(result.count)"
                            GentleFeedback.completed(playsSound: playSounds)
                        } catch { feedback = "تعذر فتح الصورة" }
                        analyzing = false
                    }
                }
                if analyzing { ProgressView("جارٍ تحليل الصورة...") }
                Button {
                    guard analyzed else { return }
                    history.add(boxes.count, mode: "صورة من الألبوم", lectureTitle: lectureName)
                    feedback = "تم حفظ العدد: \(boxes.count)"
                    GentleFeedback.completed(playsSound: playSounds)
                } label: {
                    Label("حفظ نتيجة الصورة", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!analyzed)
                if let feedback { Text(feedback).font(.footnote).foregroundStyle(.mint) }
                Text("اختر صورة واضحة تضم أجسام الطلاب قدر الإمكان. تتم المعالجة على الجهاز دون رفع الصورة إلى خادم.")
                    .font(.footnote).foregroundStyle(.secondary)
                CopyrightFooter()
            }
            .padding(18)
        }
        .background(CalmColors.background)
        .navigationTitle("تحليل الصور")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatisticsView: View {
    @EnvironmentObject private var history: CountingHistory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BrandHeader()
                Text("إحصائيات المحاضرات")
                    .font(.title3.bold())
                HStack(spacing: 10) {
                    statBox("النتائج المحفوظة", value: "\(history.records.count)", symbol: "tray.full")
                    statBox("أعلى عدد", value: "\(history.peak)", symbol: "person.3.fill")
                }
                HStack(spacing: 10) {
                    statBox("نتائج اليوم", value: "\(history.todayCount)", symbol: "calendar")
                    statBox("متوسط العدد", value: String(format: "%.1f", history.average), symbol: "chart.xyaxis.line")
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("أعلى عدد لكل يوم — آخر 7 أيام").font(.subheadline.bold())
                    Chart(history.recentDays) { day in
                        BarMark(x: .value("اليوم", day.date, unit: .day),
                                y: .value("العدد", day.peak))
                            .foregroundStyle(CalmColors.accent.gradient)
                            .cornerRadius(5)
                    }
                    .chartYScale(domain: 0...max(history.peak + 2, 5))
                    .frame(height: 230)
                    Text("الرسم يمثل أعلى نتيجة محفوظة كل يوم، وليس عدد الحاضرين الفريدين.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(14)
                .background(CalmColors.panel, in: RoundedRectangle(cornerRadius: 18))
                CopyrightFooter()
            }
            .padding(18)
        }
        .background(CalmColors.background)
        .navigationTitle("الإحصائيات")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statBox(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(CalmColors.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct HistoryView: View {
    @EnvironmentObject private var history: CountingHistory
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                if history.records.isEmpty {
                    Text("لا توجد نتائج محفوظة بعد.").foregroundStyle(.secondary)
                } else {
                    ForEach(history.records) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.lectureTitle ?? record.mode).font(.headline)
                                if record.lectureTitle != nil {
                                    Text(record.mode).font(.caption).foregroundStyle(.secondary)
                                }
                                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(record.count)")
                                .font(.title3.bold()).foregroundStyle(CalmColors.accent)
                        }
                    }
                }
            } header: { Text("عمليات العد") }
            Section {
                ShareLink(item: history.csv(), subject: Text("Hussein AI Counter"),
                          message: Text("سجل عمليات عد الطلاب")) {
                    Label("مشاركة السجل CSV كنص", systemImage: "square.and.arrow.up")
                }
                .disabled(history.records.isEmpty)
                Button("حذف كل السجلات", role: .destructive) { confirmDelete = true }
                    .disabled(history.records.isEmpty)
            }
            Section { CopyrightFooter() }
        }
        .scrollContentBackground(.hidden)
        .background(CalmColors.background)
        .navigationTitle("السجل")
        .confirmationDialog("حذف جميع النتائج المحفوظة؟", isPresented: $confirmDelete) {
            Button("حذف", role: .destructive) { history.removeAll() }
        }
    }
}

private struct CopyrightFooter: View {
    var body: some View {
        VStack(spacing: 5) {
            Text("Designed By Hussein Najah")
                .font(.footnote.bold()).foregroundStyle(.white)
            Text("© 2026 Hussein Najah. All Rights Reserved.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

/// The Vision boxes refer to upright video-buffer coordinates.
/// Map from (0...1, bottom-left origin) into the same aspectFit/aspectFill
/// image rectangle used by the camera preview; do not assume a full-screen
/// 1:1 overlay. This is critical when the camera panel is resized.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let boxes: [DetectionBox]
    let videoAspectRatio: CGFloat
    let showsCompleteFrame: Bool
    let onFocus: (CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        view.setFocusAction(onFocus)
        if let connection = view.previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.videoGravity = showsCompleteFrame ? .resizeAspect : .resizeAspectFill
        uiView.setFocusAction(onFocus)
        uiView.setBoxes(boxes, aspectRatio: videoAspectRatio, completeFrame: showsCompleteFrame)
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private var boxLayers: [CAShapeLayer] = []
    private var boxes: [DetectionBox] = []
    private var videoAspectRatio: CGFloat = 9.0 / 16.0
    private var completeFrame = true
    private var focusAction: ((CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not implemented") }

    func setFocusAction(_ action: @escaping (CGPoint) -> Void) { focusAction = action }
    @objc private func didTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        focusAction?(previewLayer.captureDevicePointConverted(fromLayerPoint: location))
    }
    override func layoutSubviews() { super.layoutSubviews(); layoutBoxes() }

    func setBoxes(_ results: [DetectionBox], aspectRatio: CGFloat, completeFrame: Bool) {
        boxes = results
        videoAspectRatio = aspectRatio
        self.completeFrame = completeFrame
        while boxLayers.count < boxes.count {
            let shape = CAShapeLayer()
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 2.4
            shape.cornerRadius = 6
            previewLayer.addSublayer(shape)
            boxLayers.append(shape)
        }
        for index in boxLayers.indices { boxLayers[index].isHidden = index >= boxes.count }
        layoutBoxes()
    }

    private func layoutBoxes() {
        guard bounds.width > 0, bounds.height > 0, videoAspectRatio > 0 else { return }
        let panelRatio = bounds.width / bounds.height
        let videoSize: CGSize
        if (completeFrame && videoAspectRatio > panelRatio) ||
           (!completeFrame && videoAspectRatio < panelRatio) {
            videoSize = CGSize(width: bounds.width, height: bounds.width / videoAspectRatio)
        } else {
            videoSize = CGSize(width: bounds.height * videoAspectRatio, height: bounds.height)
        }
        let left = (bounds.width - videoSize.width) / 2
        let top = (bounds.height - videoSize.height) / 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, detection) in boxes.enumerated() {
            let box = detection.rect
            let rect = CGRect(x: left + box.minX * videoSize.width,
                              y: top + (1 - box.maxY) * videoSize.height,
                              width: box.width * videoSize.width,
                              height: box.height * videoSize.height)
            let layer = boxLayers[index]
            layer.frame = rect
            layer.borderWidth = 2.4
            layer.borderColor = detection.kind == .face ? UIColor.systemTeal.cgColor : UIColor.systemOrange.cgColor
            layer.lineDashPattern = detection.kind == .person ? [6, 4] : nil
            layer.path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: rect.size), cornerRadius: 6).cgPath
            // A shape-layer stroke is used for the dashed fallback.
            layer.borderWidth = 0
            layer.strokeColor = detection.kind == .face ? UIColor.systemTeal.cgColor : UIColor.systemOrange.cgColor
        }
        CATransaction.commit()
    }
}

struct DetectedImage: View {
    let image: UIImage
    let boxes: [DetectionBox]

    var body: some View {
        GeometryReader { container in
            ZStack {
                Color.black
                Image(uiImage: image).resizable().scaledToFit()
                Canvas { context, size in
                    let dimensions = CGSize(width: max(image.size.width, 1), height: max(image.size.height, 1))
                    let scale = min(size.width / dimensions.width, size.height / dimensions.height)
                    let displayWidth = dimensions.width * scale
                    let displayHeight = dimensions.height * scale
                    let left = (size.width - displayWidth) / 2
                    let top = (size.height - displayHeight) / 2
                    for box in boxes {
                        let rect = CGRect(x: left + box.rect.minX * displayWidth,
                                          y: top + (1 - box.rect.maxY) * displayHeight,
                                          width: box.rect.width * displayWidth,
                                          height: box.rect.height * displayHeight)
                        let stroke = StrokeStyle(lineWidth: 2.5,
                                                 dash: box.kind == .person ? [7, 5] : [])
                        context.stroke(Path(roundedRect: rect, cornerRadius: 6),
                                       with: .color(box.kind == .face ? .mint : .orange),
                                       style: stroke)
                    }
                }
            }
            .frame(width: container.size.width, height: container.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(height: 370)
    }
}
