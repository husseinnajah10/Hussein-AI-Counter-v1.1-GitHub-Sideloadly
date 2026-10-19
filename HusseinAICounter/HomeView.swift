import SwiftUI
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers

enum CalmColors {
    static let accent = Color(red: 0.39, green: 0.68, blue: 0.75)
    static let background = Color(red: 0.055, green: 0.102, blue: 0.144)
    static let panel = Color(red: 0.100, green: 0.164, blue: 0.202)
}

struct HomeView: View {
    @StateObject private var camera = CameraCounter()

    var body: some View {
        TabView {
            NavigationStack {
                LiveCountView(camera: camera)
            }
            .tabItem { Label("الكاميرا", systemImage: "camera.viewfinder") }

            NavigationStack {
                PhotoCountView()
            }
            .tabItem { Label("الصور", systemImage: "photo.on.rectangle") }

            NavigationStack {
                HistoryView()
            }
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
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("عدّ الأشخاص داخل القاعة باستخدام الذكاء الاصطناعي")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TotalCard: View {
    let count: Int?
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Text(label).foregroundStyle(.white.opacity(0.82)).font(.subheadline)
            Text(count.map { String($0) } ?? "—")
                .font(.system(size: 78, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
                .foregroundStyle(.white)
            Text("شخصاً تم اكتشافه").font(.footnote).foregroundStyle(.white.opacity(0.73))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(LinearGradient(colors: [Color(red: 0.17, green: 0.32, blue: 0.39), Color(red: 0.09, green: 0.18, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct LiveCountView: View {
    @ObservedObject var camera: CameraCounter
    @EnvironmentObject private var history: CountingHistory
    @State private var feedback: String?
    @AppStorage("hn.camera.previewHeight") private var previewHeight: Double = 365
    @AppStorage("hn.camera.showCompleteFrame") private var showsCompleteFrame = false
    @State private var requestedZoom: Double = 1

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandHeader()
                TotalCard(count: camera.isRunning ? camera.count : nil, label: "العد المباشر")
                CameraPreview(session: camera.session, rectangles: camera.rectangles, showsCompleteFrame: showsCompleteFrame)
                    .frame(height: previewHeight)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 20))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .topLeading) {
                        Label(camera.isRunning ? "LIVE" : "OFF", systemImage: "circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(camera.isRunning ? .mint : .secondary)
                            .padding(9)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                            .padding(12)
                    }
                VStack(spacing: 12) {
                    HStack {
                        Label("حجم شاشة الكاميرا", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text("\(Int(previewHeight))")
                            .monospacedDigit()
                            .font(.footnote)
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
                    Slider(value: $requestedZoom, in: 1...max(Double(camera.maxZoomFactor), 1.01), step: 0.1)
                        .disabled(!camera.isRunning)
                        .onChange(of: requestedZoom) { _, value in
                            camera.setZoom(CGFloat(value))
                        }
                }
                .padding(14)
                .background(CalmColors.panel, in: RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 10) {
                    Button {
                        camera.isRunning ? camera.stop() : camera.start()
                    } label: {
                        Label(camera.isRunning ? "إيقاف" : "تشغيل", systemImage: camera.isRunning ? "stop.fill" : "video.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(camera.isRunning ? .red : .cyan)

                    Button { camera.takePhoto() } label: {
                        Label("التقاط", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!camera.isRunning)
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                Button {
                    guard camera.isRunning else { return }
                    history.add(camera.count, mode: "مباشر")
                    feedback = "تم حفظ العدد: \(camera.count)"
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
        .onDisappear { camera.stop() }
        .alert("مشكلة في الكاميرا", isPresented: Binding(get: { camera.errorMessage != nil }, set: { if !$0 { camera.errorMessage = nil } })) {
            Button("حسناً", role: .cancel) { camera.errorMessage = nil }
        } message: {
            Text(camera.errorMessage ?? "")
        }
        .sheet(item: $camera.capture) { result in
            NavigationStack {
                VStack(spacing: 16) {
                    TotalCard(count: result.rectangles.count, label: "نتيجة الصورة الملتقطة")
                    DetectedImage(image: result.image, boxes: result.rectangles)
                    Button("حفظ هذا العدد") {
                        history.add(result.rectangles.count, mode: "التقاط صورة")
                        camera.capture = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CalmColors.accent)
                    Spacer()
                }
                .padding()
                .navigationTitle("الصورة الملتقطة")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("إغلاق") { camera.capture = nil } } }
            }
        }
    }
}

struct PhotoCountView: View {
    @EnvironmentObject private var history: CountingHistory
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var boxes: [CGRect] = []
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
                                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 50))
                                Text("اختر صورة للقاعة لتحليلها").font(.headline)
                            }
                            .foregroundStyle(.secondary)
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
                            guard let data = try await item.loadTransferable(type: Data.self), let picture = UIImage(data: data) else {
                                feedback = "تعذر قراءة الصورة"; analyzing = false; return
                            }
                            let detections = await Task.detached(priority: .userInitiated) {
                                PhotoDetector.detect(in: picture)
                            }.value
                            image = picture
                            boxes = detections
                            analyzed = true
                        } catch { feedback = "تعذر فتح الصورة" }
                        analyzing = false
                    }
                }
                if analyzing { ProgressView("جارٍ تحليل الصورة...") }
                Button {
                    guard analyzed else { return }
                    history.add(boxes.count, mode: "صورة من الألبوم")
                    feedback = "تم حفظ العدد: \(boxes.count)"
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
                            VStack(alignment: .leading) {
                                Text(record.mode).font(.headline)
                                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(record.count)").font(.title3.bold()).foregroundStyle(.cyan)
                        }
                    }
                }
            } header: { Text("عمليات العد") }
            Section {
                ShareLink(item: history.csv(), subject: Text("Hussein AI Counter"), message: Text("سجل عمليات عد الطلاب")) {
                    Label("مشاركة السجل CSV كنص", systemImage: "square.and.arrow.up")
                }
                .disabled(history.records.isEmpty)
                Button("حذف كل السجلات", role: .destructive) { confirmDelete = true }
                    .disabled(history.records.isEmpty)
            }
            Section {
                CopyrightFooter()
            }
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
                .font(.footnote.bold())
                .foregroundStyle(.white)
            Text("© 2026 Hussein Najah. All Rights Reserved.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let rectangles: [CGRect]
    let showsCompleteFrame: Bool

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = showsCompleteFrame ? .resizeAspect : .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.videoGravity = showsCompleteFrame ? .resizeAspect : .resizeAspectFill
        uiView.setBoxes(rectangles)
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private var boxLayers: [CAShapeLayer] = []
    private var visibleBoxes: [CGRect] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBoxes()
    }

    func setBoxes(_ rectangles: [CGRect]) {
        visibleBoxes = rectangles
        while boxLayers.count < rectangles.count {
            let box = CAShapeLayer()
            box.borderColor = UIColor.systemTeal.cgColor
            box.borderWidth = 2.5
            box.cornerRadius = 7
            box.fillColor = UIColor.clear.cgColor
            previewLayer.addSublayer(box)
            boxLayers.append(box)
        }
        for (index, layer) in boxLayers.enumerated() {
            layer.isHidden = index >= rectangles.count
        }
        layoutBoxes()
    }

    private func layoutBoxes() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, rectangle) in visibleBoxes.enumerated() {
            let metadataRect = CGRect(x: rectangle.minX,
                                      y: 1 - rectangle.maxY,
                                      width: rectangle.width,
                                      height: rectangle.height)
            boxLayers[index].frame = previewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)
        }
        CATransaction.commit()
    }
}

struct DetectedImage: View {
    let image: UIImage
    let boxes: [CGRect]

    var body: some View {
        GeometryReader { container in
            ZStack {
                Color.black
                Image(uiImage: image).resizable().scaledToFit()
                Canvas { context, size in
                    let imageSize = CGSize(width: image.size.width, height: image.size.height)
                    let scale = min(size.width / imageSize.width, size.height / imageSize.height)
                    let renderedW = imageSize.width * scale
                    let renderedH = imageSize.height * scale
                    let left = (size.width - renderedW) / 2
                    let top = (size.height - renderedH) / 2
                    for box in boxes {
                        let rect = CGRect(x: left + box.minX * renderedW,
                                          y: top + (1 - box.maxY) * renderedH,
                                          width: box.width * renderedW, height: box.height * renderedH)
                        context.stroke(Path(roundedRect: rect, cornerRadius: 5), with: .color(.mint), lineWidth: 2.5)
                    }
                }
            }
            .frame(width: container.size.width, height: container.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(height: 370)
    }
}
