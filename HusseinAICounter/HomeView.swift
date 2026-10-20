import SwiftUI
import AVFoundation
import PhotosUI
import Charts
import UIKit

private enum MainTab: Int, CaseIterable {
    case statistics, camera, history, settings
    var icon: String {
        switch self {
        case .statistics: return "chart.bar.fill"
        case .camera: return "camera.viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
    func name(_ p: AppPreferences) -> String {
        switch self {
        case .statistics: return p.tr("الإحصائيات", "Statistics")
        case .camera: return p.tr("الكاميرا", "Camera")
        case .history: return p.tr("السجل", "History")
        case .settings: return p.tr("الإعدادات", "Settings")
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var prefs: AppPreferences
    @StateObject private var camera = CameraCounter()
    @State private var active: MainTab = .statistics

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch active {
                case .statistics: StatisticsScreen()
                case .camera: CameraScreen(camera: camera)
                case .history: HistoryScreen()
                case .settings: SettingsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 4) {
                ForEach(MainTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                            active = tab
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 50, height: 45)
                                .background(active == tab ? GoldTeal.goldGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                                            in: RoundedRectangle(cornerRadius: 17))
                                .foregroundStyle(active == tab ? GoldTeal.background : GoldTeal.subtle)
                                .scaleEffect(active == tab ? 1.12 : 1)
                                .offset(y: active == tab ? -8 : 0)
                                .shadow(color: active == tab ? GoldTeal.gold.opacity(0.25) : .clear,
                                        radius: 12, y: 4)
                            Text(tab.name(prefs))
                                .font(.system(size: 10, weight: active == tab ? .bold : .medium))
                                .foregroundStyle(active == tab ? GoldTeal.goldLight : GoldTeal.subtle)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(active == tab ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 9)
            .padding(.top, 14)
            .padding(.bottom, 7)
            .background(GoldTeal.background)
            .overlay(alignment: .top) { Rectangle().fill(GoldTeal.gold.opacity(0.22)).frame(height: 1) }
        }
        .background(GoldTeal.backdrop.ignoresSafeArea())
    }
}

private struct PageHeading: View {
    @EnvironmentObject private var prefs: AppPreferences
    let subtitleAR: String
    let subtitleEN: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Student AI Counter")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(GoldTeal.goldLight)
                    Text(prefs.tr(subtitleAR, subtitleEN))
                        .font(.footnote).foregroundStyle(GoldTeal.subtle)
                }
                Spacer()
                Image("GoldenGate")
                    .resizable().scaledToFit().frame(width: 56, height: 56)
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let number: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol).foregroundStyle(GoldTeal.gold)
            Text(number)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit().foregroundStyle(.white)
            Text(title).font(.caption).foregroundStyle(GoldTeal.subtle)
                .lineLimit(2).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(GoldTeal.raised, in: RoundedRectangle(cornerRadius: 17))
    }
}

struct StatisticsScreen: View {
    @EnvironmentObject private var prefs: AppPreferences
    @EnvironmentObject private var history: CountingHistory

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PageHeading(subtitleAR: "لوحة الإحصائيات", subtitleEN: "Statistics dashboard")
                GoldPanel {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(prefs.tr("سجل المحاضرات", "Lecture records"))
                                .foregroundStyle(GoldTeal.subtle).font(.subheadline)
                            Text("\(history.records.count)")
                                .font(.system(size: 49, weight: .bold, design: .rounded))
                                .foregroundStyle(GoldTeal.goldLight)
                            Text(prefs.tr("كل النتائج المحفوظة", "All saved counts"))
                                .font(.caption).foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 43)).foregroundStyle(GoldTeal.teal)
                    }
                }
                HStack(spacing: 12) {
                    MetricTile(title: prefs.tr("أعلى عدد", "Highest count"), number: "\(history.peak)", symbol: "arrow.up.forward")
                    MetricTile(title: prefs.tr("متوسط العدد", "Average count"), number: String(format: "%.1f", history.average), symbol: "chart.line.uptrend.xyaxis")
                }
                HStack(spacing: 12) {
                    MetricTile(title: prefs.tr("نتائج اليوم", "Today's results"), number: "\(history.todayCount)", symbol: "calendar")
                    MetricTile(title: prefs.tr("آخر كشف", "Last detection"), number: history.latestObservation.map { "\($0.count)" } ?? "—", symbol: "viewfinder")
                }
                GoldPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(prefs.tr("آخر سبعة أيام", "Last seven days"), systemImage: "chart.bar.xaxis")
                            .font(.headline).foregroundStyle(GoldTeal.goldLight)
                        Chart(history.recentDays) { day in
                            BarMark(x: .value("Day", day.date, unit: .day), y: .value("Peak", day.peak))
                                .foregroundStyle(GoldTeal.teal.gradient)
                                .cornerRadius(4)
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .frame(height: 190)
                    }
                }
                GoldPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(prefs.tr("آخر المحاضرات", "Recent lectures"))
                            .font(.headline).foregroundStyle(GoldTeal.goldLight)
                        if history.records.isEmpty {
                            Text(prefs.tr("لا توجد نتائج محفوظة بعد", "No saved results yet"))
                                .foregroundStyle(GoldTeal.subtle).font(.subheadline)
                        } else {
                            ForEach(history.records.prefix(4)) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.lectureTitle ?? prefs.tr("محاضرة", "Lecture"))
                                            .foregroundStyle(.white).font(.subheadline.bold())
                                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                            .foregroundStyle(GoldTeal.subtle).font(.caption2)
                                    }
                                    Spacer()
                                    Text("\(entry.count)").font(.title3.bold()).foregroundStyle(GoldTeal.goldLight)
                                }
                                Divider().overlay(GoldTeal.gold.opacity(0.1))
                            }
                        }
                    }
                }
                CreditFooter()
            }
            .padding(17)
        }
        .background(GoldTeal.backdrop)
    }
}

private enum CountMode: String, CaseIterable { case live, photo }

struct CameraScreen: View {
    @ObservedObject var camera: CameraCounter
    @EnvironmentObject private var history: CountingHistory
    @EnvironmentObject private var prefs: AppPreferences
    @AppStorage("sac.lectureTitle") private var lectureTitle = ""
    @State private var mode: CountMode = .live
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var analyzedPhoto: CapturedCount?
    @State private var analyzingPhoto = false
    @State private var status: String?
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PageHeading(subtitleAR: "العد الذكي بالكاميرا", subtitleEN: "Smart camera counting")
                HStack(spacing: 8) {
                    modeButton(.live, icon: "video.fill", ar: "العد المباشر", en: "Live count")
                    modeButton(.photo, icon: "photo.fill", ar: "العد من صورة", en: "Photo count")
                }
                .padding(5)
                .background(GoldTeal.surface, in: RoundedRectangle(cornerRadius: 18))
                ZStack(alignment: .top) {
                    CameraPreview(session: camera.session, boxes: mode == .live ? camera.boxes : [],
                                  videoAspectRatio: camera.videoAspectRatio,
                                  mirrored: camera.cameraPosition == .front,
                                  onFocus: { camera.focus(at: $0) },
                                  onZoom: { camera.adjustZoom(by: $0) })
                        .frame(maxWidth: .infinity)
                        .frame(height: 385)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 21))
                    HStack {
                        Label(camera.isRunning ? "LIVE" : "OFF", systemImage: "circle.fill")
                            .foregroundStyle(camera.isRunning ? GoldTeal.teal : .gray)
                        Spacer()
                        Text(String(format: "%.1f×", camera.zoomFactor))
                            .foregroundStyle(GoldTeal.goldLight)
                    }
                    .font(.caption.bold()).padding(11)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    .padding(12)
                }
                if mode == .live {
                    Text(prefs.tr("الوجه المكتشف بإطار تركوازي، والشخص بدون وجه واضح بإطار ذهبي متقطع.",
                                  "Faces have teal boxes; people with no visible face have dashed gold boxes."))
                        .font(.caption).foregroundStyle(GoldTeal.subtle)
                } else {
                    Text(prefs.tr("التقط صورة أو اختر من الألبوم لتحليلها بشكل مستقل.",
                                  "Capture or import a photo to analyze it separately."))
                        .font(.caption).foregroundStyle(GoldTeal.subtle)
                }
                GoldPanel {
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Button { camera.flipCamera() } label: {
                                Label(prefs.tr("تبديل الكاميرا", "Flip camera"), systemImage: "arrow.triangle.2.circlepath.camera")
                            }
                            .disabled(!camera.isRunning)
                            Spacer()
                            if camera.cameraPosition == .back && camera.supportsUltraWide {
                                Button("0.5×") { camera.setLens(.ultraWide) }
                                    .foregroundStyle(camera.selectedLens == .ultraWide ? GoldTeal.goldLight : GoldTeal.subtle)
                            }
                            if camera.cameraPosition == .back {
                                Button("1×") { camera.setLens(.wide) }
                                    .foregroundStyle(camera.selectedLens == .wide ? GoldTeal.goldLight : GoldTeal.subtle)
                            }
                            Button { camera.setTorch(!camera.torchEnabled) } label: {
                                Image(systemName: camera.torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                            }
                            .disabled(!camera.isRunning || !camera.supportsTorch)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoldTeal.teal)
                        Text(prefs.tr("قرّب أو بعّد بإصبعين داخل صورة الكاميرا، واضغط للتركيز.",
                                      "Pinch with two fingers to zoom; tap the preview to focus."))
                            .font(.caption).foregroundStyle(GoldTeal.subtle)
                        HStack(spacing: 10) {
                            Button {
                                camera.isRunning ? camera.stop() : camera.start()
                            } label: {
                                Label(camera.isRunning ? prefs.tr("إيقاف", "Stop") : prefs.tr("تشغيل", "Start"),
                                      systemImage: camera.isRunning ? "stop.fill" : "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent).tint(GoldTeal.teal)
                            if mode == .photo {
                                Button { camera.takePhoto() } label: {
                                    Label(prefs.tr("التقاط صورة", "Take photo"), systemImage: "camera.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered).tint(GoldTeal.gold)
                                .disabled(!camera.isRunning)
                            }
                        }
                        .controlSize(.large)
                    }
                }
                if mode == .live { liveControls }
                else { photoControls }
                if let status {
                    Text(status).font(.footnote).foregroundStyle(GoldTeal.teal)
                }
                CreditFooter()
            }
            .padding(16)
        }
        .background(GoldTeal.backdrop)
        .onAppear { camera.start() }
        .onDisappear { saveTask?.cancel(); camera.stop() }
        .onChange(of: camera.count) { _, newCount in
            scheduleAutoSave(newCount)
        }
        .onChange(of: camera.latestDetectionAt) { _, timestamp in
            guard camera.isRunning && mode == .live else { return }
            history.updateLiveObservation(count: camera.count,
                                          faces: camera.facesDetected, timestamp: timestamp)
        }
        .onChange(of: camera.capture?.id) { _, _ in
            guard let picture = camera.capture else { return }
            analyzedPhoto = picture
            history.add(picture.count, mode: "Photo", lectureTitle: lectureTitle)
            prefs.feedback()
            camera.capture = nil
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let picture = UIImage(data: data) else { return }
                analyzeImportedImage(picture)
            }
        }
        .sheet(item: $analyzedPhoto) { sample in
            PhotoResultSheet(sample: sample)
        }
        .alert(prefs.tr("مشكلة في الكاميرا", "Camera issue"), isPresented: Binding(
            get: { camera.errorMessage != nil },
            set: { if !$0 { camera.errorMessage = nil } }
        )) { Button(prefs.tr("حسناً", "OK"), role: .cancel) { camera.errorMessage = nil } }
        message: { Text(camera.errorMessage ?? "") }
    }

    private func modeButton(_ target: CountMode, icon: String, ar: String, en: String) -> some View {
        Button {
            mode = target
            saveTask?.cancel()
        } label: {
            Label(prefs.tr(ar, en), systemImage: icon)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .foregroundStyle(mode == target ? GoldTeal.background : GoldTeal.goldLight)
                .background(mode == target ? GoldTeal.gold : .clear,
                            in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private var liveControls: some View {
        VStack(spacing: 13) {
            GoldPanel {
                HStack {
                    VStack(alignment: .leading) {
                        Text(prefs.tr("العدد الحالي", "Current count"))
                            .foregroundStyle(GoldTeal.subtle)
                        Text(camera.isRunning ? "\(camera.count)" : "—")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(GoldTeal.goldLight)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(camera.facesDetected) " + prefs.tr("وجه", "faces"))
                        Text("\(max(0, camera.count - camera.facesDetected)) " + prefs.tr("شخص", "people"))
                    }
                    .font(.subheadline).foregroundStyle(GoldTeal.teal)
                }
            }
            TextField(prefs.tr("اسم المحاضرة (اختياري)", "Lecture name (optional)"), text: $lectureTitle)
                .textFieldStyle(.roundedBorder)
            HStack {
                Text(prefs.tr("حفظ تلقائي للعدد المستقر", "Auto-save stable count"))
                Spacer()
                Toggle("", isOn: $prefs.autoSave).labelsHidden().tint(GoldTeal.teal)
            }
            .font(.subheadline).foregroundStyle(.white)
            Button {
                history.add(camera.count, mode: "Live", lectureTitle: lectureTitle)
                status = prefs.tr("تم حفظ العدد", "Count saved")
                prefs.feedback()
            } label: {
                Label(prefs.tr("حفظ العدد الآن", "Save count now"), systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(GoldTeal.gold)
            .disabled(!camera.isRunning)
            Text(prefs.tr("يُحدَّث آخر كشف محلياً كل نحو 0.8 ثانية عند توفر النتائج. التدوين في سجل المحاضرات يتم عند استقرار العدد. لا تُخزَّن صور الطلاب.",
                          "Latest detection is saved locally about every 0.8 seconds when results are available. Lecture records are saved after the count stabilizes. No student photos are stored."))
                .font(.caption2).foregroundStyle(GoldTeal.subtle)
        }
    }

    private var photoControls: some View {
        GoldPanel {
            VStack(spacing: 12) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label(prefs.tr("اختيار صورة من الألبوم", "Choose from Photos"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(GoldTeal.teal)
                if analyzingPhoto {
                    ProgressView(prefs.tr("جاري تحليل الصورة...", "Analyzing photo..."))
                        .tint(GoldTeal.gold)
                }
                Text(prefs.tr("تُحفظ نتيجة الصورة تلقائياً في السجل بدون حفظ الصورة نفسها.",
                              "Photo results are automatically logged without storing the photo."))
                    .font(.caption).foregroundStyle(GoldTeal.subtle)
            }
        }
    }

    private func analyzeImportedImage(_ image: UIImage) {
        analyzingPhoto = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PhotoDetector.detect(in: image)
            DispatchQueue.main.async {
                let sample = CapturedCount(image: image, boxes: result.boxes)
                analyzedPhoto = sample
                history.add(result.count, mode: "Photo", lectureTitle: lectureTitle)
                prefs.feedback()
                analyzingPhoto = false
            }
        }
    }

    private func scheduleAutoSave(_ value: Int) {
        saveTask?.cancel()
        guard mode == .live, prefs.autoSave, camera.isRunning, value > 0 else { return }
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled && camera.isRunning && mode == .live && camera.count == value else { return }
            if history.addAutoSnapshot(value, mode: "Live — Auto", lectureTitle: lectureTitle) {
                status = prefs.tr("تم الحفظ التلقائي", "Auto-saved")
                prefs.feedback()
            }
        }
    }
}

private struct PhotoResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var prefs: AppPreferences
    let sample: CapturedCount
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("\(sample.count)")
                        .font(.system(size: 66, weight: .bold, design: .rounded))
                        .foregroundStyle(GoldTeal.goldLight)
                    Text(prefs.tr("أشخاص تم اكتشافهم", "People detected"))
                        .foregroundStyle(GoldTeal.subtle)
                    DetectedImage(image: sample.image, boxes: sample.boxes)
                    Text(prefs.tr("الإطارات التركوازية للوجوه، والذهبية المتقطعة للأشخاص الآخرين.",
                                  "Teal boxes show faces; dashed gold boxes show other people."))
                        .foregroundStyle(GoldTeal.subtle).font(.caption)
                }.padding()
            }
            .background(GoldTeal.background)
            .navigationTitle(prefs.tr("نتيجة الصورة", "Photo result"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button(prefs.tr("إغلاق", "Close")) { dismiss() }
            } }
        }
        .preferredColorScheme(.dark)
    }
}

struct HistoryScreen: View {
    @EnvironmentObject private var prefs: AppPreferences
    @EnvironmentObject private var history: CountingHistory
    @State private var confirmsErase = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PageHeading(subtitleAR: "سجل المحاضرات والنتائج", subtitleEN: "Lecture count history")
                HStack {
                    ShareLink(item: history.csv()) {
                        Label(prefs.tr("تصدير CSV", "Export CSV"), systemImage: "square.and.arrow.up")
                            .foregroundStyle(GoldTeal.goldLight)
                    }
                    Spacer()
                    Button(role: .destructive) { confirmsErase = true } label: {
                        Label(prefs.tr("مسح السجل", "Clear history"), systemImage: "trash")
                    }
                    .disabled(history.records.isEmpty)
                }
                .font(.subheadline)
                if history.records.isEmpty {
                    GoldPanel {
                        Text(prefs.tr("ماكو نتائج محفوظة بعد. تگدر تستخدم العد المباشر أو الصور.",
                                      "No saved results yet. Try live or photo counting."))
                            .foregroundStyle(GoldTeal.subtle)
                    }
                } else {
                    ForEach(history.records) { result in
                        GoldPanel {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(result.lectureTitle ?? prefs.tr("محاضرة", "Lecture"))
                                        .font(.subheadline.bold()).foregroundStyle(.white)
                                    Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(GoldTeal.subtle)
                                    Text(result.mode)
                                        .font(.caption2).foregroundStyle(GoldTeal.teal)
                                }
                                Spacer()
                                Text("\(result.count)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(GoldTeal.goldLight)
                            }
                        }
                    }
                }
                CreditFooter()
            }
            .padding(16)
        }
        .background(GoldTeal.backdrop)
        .confirmationDialog(prefs.tr("مسح كل النتائج؟", "Delete all records?"), isPresented: $confirmsErase) {
            Button(prefs.tr("حذف الكل", "Delete all"), role: .destructive) { history.removeAll() }
        }
    }
}

struct SettingsScreen: View {
    @EnvironmentObject private var prefs: AppPreferences
    @State private var editingProfile = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PageHeading(subtitleAR: "تفضيلات التطبيق", subtitleEN: "App preferences")
                GoldPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(prefs.tr("تسجيل الدخول (اختياري)", "Sign in (optional)"), systemImage: "person.crop.circle")
                            .font(.headline).foregroundStyle(GoldTeal.goldLight)
                        Text(prefs.tr("هذا ملف مستخدم محلي للعرض فقط، وليس حساباً على الإنترنت. تگدر تستخدم التطبيق بدون تسجيل دخول.",
                                      "This is a local display profile, not an online account. No sign-in is required."))
                            .font(.caption).foregroundStyle(GoldTeal.subtle)
                        TextField(prefs.tr("اسم المستخدم", "Display name"), text: $prefs.localDisplayName)
                            .textFieldStyle(.roundedBorder)
                        Text(prefs.localDisplayName.isEmpty ? prefs.tr("الوضع الحالي: ضيف", "Current mode: Guest") :
                             prefs.tr("مرحباً، ", "Welcome, ") + prefs.localDisplayName)
                            .font(.subheadline).foregroundStyle(GoldTeal.teal)
                        Button(prefs.tr("المتابعة كضيف", "Continue as guest")) { prefs.localDisplayName = "" }
                            .foregroundStyle(GoldTeal.goldLight).font(.subheadline)
                    }
                }
                GoldPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(prefs.tr("اللغة", "Language"), systemImage: "globe")
                            .font(.headline).foregroundStyle(GoldTeal.goldLight)
                        Picker(prefs.tr("اللغة", "Language"), selection: $prefs.english) {
                            Text("العربية").tag(false)
                            Text("English").tag(true)
                        }
                        .pickerStyle(.segmented)
                        Toggle(prefs.tr("أصوات وتنبيهات خفيفة", "Gentle sounds and feedback"), isOn: $prefs.soundsEnabled)
                            .tint(GoldTeal.teal)
                        Toggle(prefs.tr("الحفظ التلقائي", "Automatic saving"), isOn: $prefs.autoSave)
                            .tint(GoldTeal.teal)
                    }
                    .foregroundStyle(.white)
                }
                GoldPanel {
                    VStack(alignment: .leading, spacing: 13) {
                        Label(prefs.tr("معلومات التطبيق", "About this app"), systemImage: "info.circle")
                            .font(.headline).foregroundStyle(GoldTeal.goldLight)
                        LabeledContent(prefs.tr("الاسم", "Name"), value: "Student AI Counter")
                        LabeledContent(prefs.tr("العلامة", "Brand"), value: "Golden Gate")
                        LabeledContent(prefs.tr("الإصدار", "Version"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")
                        LabeledContent(prefs.tr("البناء", "Build"), value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "4")
                        Text(prefs.tr("التحليل يتم على الجهاز. لا يوجد اتصال بخدمة حسابات أو تخزين سحابي.",
                                      "Detection happens on device. No account service or cloud storage is used."))
                            .font(.caption).foregroundStyle(GoldTeal.subtle)
                    }
                    .font(.subheadline)
                }
                CreditFooter()
            }.padding(16)
        }
        .background(GoldTeal.backdrop)
    }
}

/// Vision provides boxes in normalized coordinates, bottom-left origin.
/// Scale the boxes to the same video rect used by the preview (aspectFit),
/// and mirror only the front-camera preview, never the Vision input.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let boxes: [DetectionBox]
    let videoAspectRatio: CGFloat
    let mirrored: Bool
    let onFocus: (CGPoint) -> Void
    let onZoom: (CGFloat) -> Void

    func makeUIView(context: Context) -> DetectionPreviewView {
        let view = DetectionPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        view.setHandlers(focus: onFocus, zoom: onZoom)
        if let connection = view.previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        return view
    }
    func updateUIView(_ uiView: DetectionPreviewView, context: Context) {
        uiView.setHandlers(focus: onFocus, zoom: onZoom)
        uiView.updateBoxes(boxes, ratio: videoAspectRatio, mirrored: mirrored)
    }
}

final class DetectionPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    private var shapes: [CAShapeLayer] = []
    private var current: [DetectionBox] = []
    private var videoRatio: CGFloat = 9.0 / 16.0
    private var mirrored = false
    private var focusHandler: ((CGPoint) -> Void)?
    private var zoomHandler: ((CGFloat) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
        addGestureRecognizer(pinch)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setHandlers(focus: @escaping (CGPoint) -> Void, zoom: @escaping (CGFloat) -> Void) {
        focusHandler = focus
        zoomHandler = zoom
    }
    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        focusHandler?(previewLayer.captureDevicePointConverted(fromLayerPoint: recognizer.location(in: self)))
    }
    @objc private func pinched(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state == .changed else { return }
        zoomHandler?(recognizer.scale)
        recognizer.scale = 1
    }
    override func layoutSubviews() { super.layoutSubviews(); drawBoxes() }

    func updateBoxes(_ boxes: [DetectionBox], ratio: CGFloat, mirrored: Bool) {
        current = boxes
        videoRatio = max(0.01, ratio)
        self.mirrored = mirrored
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = mirrored
        }
        while shapes.count < boxes.count {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 2.5
            previewLayer.addSublayer(layer)
            shapes.append(layer)
        }
        for (i, layer) in shapes.enumerated() { layer.isHidden = i >= boxes.count }
        drawBoxes()
    }
    private func drawBoxes() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let width = min(bounds.width, bounds.height * videoRatio)
        let height = min(bounds.height, bounds.width / videoRatio)
        let left = (bounds.width - width) / 2
        let top = (bounds.height - height) / 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, result) in current.enumerated() {
            let rect = result.rect
            let normalizedX = mirrored ? 1 - rect.maxX : rect.minX
            let frame = CGRect(x: left + normalizedX * width,
                               y: top + (1 - rect.maxY) * height,
                               width: rect.width * width, height: rect.height * height)
            let shape = shapes[index]
            shape.frame = frame
            shape.path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: frame.size), cornerRadius: 7).cgPath
            shape.strokeColor = (result.kind == .face ? UIColor.systemTeal : UIColor.systemYellow).cgColor
            shape.lineDashPattern = result.kind == .person ? [6, 4] : nil
        }
        CATransaction.commit()
    }
}

struct DetectedImage: View {
    let image: UIImage
    let boxes: [DetectionBox]
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                Color.black
                Image(uiImage: image).resizable().scaledToFit()
                Canvas { ctx, size in
                    let original = CGSize(width: max(1, image.size.width), height: max(1, image.size.height))
                    let scale = min(size.width / original.width, size.height / original.height)
                    let w = original.width * scale
                    let h = original.height * scale
                    let x = (size.width - w) / 2
                    let y = (size.height - h) / 2
                    for box in boxes {
                        let rect = CGRect(x: x + box.rect.minX * w,
                                          y: y + (1 - box.rect.maxY) * h,
                                          width: box.rect.width * w, height: box.rect.height * h)
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 6),
                                   with: .color(box.kind == .face ? GoldTeal.teal : GoldTeal.gold),
                                   style: StrokeStyle(lineWidth: 2.5, dash: box.kind == .person ? [6, 4] : []))
                    }
                }
            }
            .frame(width: bounds.size.width, height: bounds.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .frame(height: 390)
    }
}
