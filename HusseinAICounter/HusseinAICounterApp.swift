import SwiftUI

@main
struct HusseinAICounterApp: App {
    @StateObject private var records = CountingHistory()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(records)
                .preferredColorScheme(.dark)
        }
    }
}
