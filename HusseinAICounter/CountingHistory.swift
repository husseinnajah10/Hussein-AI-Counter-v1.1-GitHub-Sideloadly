import Foundation
import Combine

// New optional lectureTitle decodes existing v1 records without migration.
struct CountingRecord: Identifiable, Codable {
    var id: UUID = UUID()
    let timestamp: Date
    let count: Int
    let mode: String
    var lectureTitle: String? = nil
}

struct DailyCount: Identifiable {
    let date: Date
    let peak: Int
    let entries: Int
    var id: Date { date }
}

struct LiveObservation: Codable {
    let timestamp: Date
    let count: Int
    let faces: Int
}

final class CountingHistory: ObservableObject {
    @Published private(set) var records: [CountingRecord] = []
    // Same key as versions 1/2: existing lesson logs survive normal updates.
    private let key = "HusseinAICounter.CountingHistory.v1"
    private let observationKey = "StudentAICounter.latestDetection.v3"
    @Published private(set) var latestObservation: LiveObservation?
    private var lastObservationWrite: Date = .distantPast

    init() {
        if let data = UserDefaults.standard.data(forKey: observationKey) {
            latestObservation = try? JSONDecoder().decode(LiveObservation.self, from: data)
        }
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([CountingRecord].self, from: data) else { return }
        records = saved
    }

    func add(_ count: Int, mode: String, lectureTitle: String? = nil) {
        let name = lectureTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        records.insert(CountingRecord(timestamp: Date(), count: max(count, 0), mode: mode,
                                      lectureTitle: name?.isEmpty == false ? name : nil), at: 0)
        if records.count > 1000 { records = Array(records.prefix(1000)) }
        persist()
    }

    /// Log only a stable nonzero result, not every camera frame.
    /// Avoid duplicate auto snapshots of the same count and lecture over 90s.
    @discardableResult
    func addAutoSnapshot(_ count: Int, mode: String = "مباشر — تلقائي", lectureTitle: String? = nil) -> Bool {
        guard count > 0 else { return false }
        let title = lectureTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = title?.isEmpty == false ? title : nil
        if let last = records.first(where: { $0.mode == mode && $0.lectureTitle == normalized }),
           last.count == count, Date().timeIntervalSince(last.timestamp) < 90 { return false }
        // Never save more than one automatic snapshot every 20 seconds.
        if let mostRecentAuto = records.first(where: { $0.mode == mode }),
           Date().timeIntervalSince(mostRecentAuto.timestamp) < 20 { return false }
        add(count, mode: mode, lectureTitle: normalized)
        return true
    }

    /// Records the latest detection locally about once per 0.8 seconds;
    /// this is separate from the permanent lecture history and stores no photo.
    func updateLiveObservation(count: Int, faces: Int, timestamp: Date) {
        guard timestamp.timeIntervalSince(lastObservationWrite) >= 0.8 else { return }
        let sample = LiveObservation(timestamp: timestamp, count: max(0, count), faces: max(0, faces))
        latestObservation = sample
        lastObservationWrite = timestamp
        if let data = try? JSONEncoder().encode(sample) {
            UserDefaults.standard.set(data, forKey: observationKey)
        }
    }

    func removeAll() {
        records.removeAll()
        persist()
    }

    var peak: Int { records.map(\.count).max() ?? 0 }
    var average: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1.count }) / Double(records.count)
    }
    var todayCount: Int {
        records.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    var recentDays: [DailyCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> DailyCount? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let values = records.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            return DailyCount(date: date, peak: values.map(\.count).max() ?? 0, entries: values.count)
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func csv() -> String {
        let rows = records.map { record in
            let name = (record.lectureTitle ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let mode = record.mode.replacingOccurrences(of: "\"", with: "\"\"")
            return "\(ISO8601DateFormatter().string(from: record.timestamp)),\(record.count),\"\(mode)\",\"\(name)\""
        }
        return "date,count,mode,lecture\n" + rows.joined(separator: "\n")
    }
}
