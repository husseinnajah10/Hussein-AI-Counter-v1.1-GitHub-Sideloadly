import Foundation
import Combine

struct CountingRecord: Identifiable, Codable {
    var id: UUID = UUID()
    let timestamp: Date
    let count: Int
    let mode: String
}

final class CountingHistory: ObservableObject {
    @Published private(set) var records: [CountingRecord] = []
    private let key = "HusseinAICounter.CountingHistory.v1"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([CountingRecord].self, from: data) else { return }
        records = saved
    }

    func add(_ count: Int, mode: String) {
        records.insert(CountingRecord(timestamp: Date(), count: count, mode: mode), at: 0)
        if records.count > 500 { records = Array(records.prefix(500)) }
        persist()
    }

    func removeAll() {
        records.removeAll()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func csv() -> String {
        let rows = records.map { record in
            "\(ISO8601DateFormatter().string(from: record.timestamp)),\(record.count),\(record.mode)"
        }
        return "date,count,mode\n" + rows.joined(separator: "\n")
    }
}
