import SwiftUI

@main
struct HusseinAICounterApp: App {
    @StateObject private var records = CountingHistory()
    @StateObject private var prefs = AppPreferences()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(records)
                .environmentObject(prefs)
                .environment(\.layoutDirection, prefs.english ? .leftToRight : .rightToLeft)
                .preferredColorScheme(.dark)
        }
    }
}
