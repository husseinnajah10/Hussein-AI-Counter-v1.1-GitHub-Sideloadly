import SwiftUI
import Combine
import AudioToolbox
import UIKit

/// A small bilingual preference object; no server or network account is used.
final class AppPreferences: ObservableObject {
    @Published var english: Bool {
        didSet { UserDefaults.standard.set(english, forKey: "sac.language.english") }
    }
    @Published var localDisplayName: String {
        didSet { UserDefaults.standard.set(localDisplayName, forKey: "sac.profile.name") }
    }
    @Published var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: "sac.sound") }
    }
    @Published var autoSave: Bool {
        didSet { UserDefaults.standard.set(autoSave, forKey: "sac.autoSave") }
    }
    init() {
        self.english = UserDefaults.standard.bool(forKey: "sac.language.english")
        self.localDisplayName = UserDefaults.standard.string(forKey: "sac.profile.name") ?? ""
        self.soundsEnabled = UserDefaults.standard.bool(forKey: "sac.sound")
        self.autoSave = UserDefaults.standard.object(forKey: "sac.autoSave") as? Bool ?? true
    }
    func tr(_ ar: String, _ en: String) -> String { english ? en : ar }
    func feedback() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if soundsEnabled { AudioServicesPlaySystemSound(1104) }
    }
}

enum GoldTeal {
    static let background = Color(red: 0.028, green: 0.091, blue: 0.106)
    static let surface = Color(red: 0.057, green: 0.156, blue: 0.174)
    static let raised = Color(red: 0.075, green: 0.201, blue: 0.214)
    static let gold = Color(red: 0.92, green: 0.744, blue: 0.399)
    static let goldLight = Color(red: 1, green: 0.902, blue: 0.688)
    static let teal = Color(red: 0.28, green: 0.819, blue: 0.754)
    static let subtle = Color(red: 0.657, green: 0.769, blue: 0.762)
    static let goldGradient = LinearGradient(colors: [goldLight, gold, Color(red: 0.65, green: 0.41, blue: 0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let backdrop = LinearGradient(colors: [background, Color(red: 0.023, green: 0.16, blue: 0.171), background], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct GoldPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GoldTeal.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(GoldTeal.gold.opacity(0.16), lineWidth: 1))
    }
}

struct CreditFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Designed By Hussein Najah")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GoldTeal.goldLight)
            Text("© 2026 Hussein Najah. All Rights Reserved.")
                .font(.caption2).foregroundStyle(GoldTeal.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
