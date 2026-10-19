import SwiftUI

/// The welcome screen uses the same HN artwork as the iPhone app icon.
/// Only a quiet scale-and-fade entrance is used; no extra visual effects.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Spacer()
                Image("LaunchMonogram")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: min(geometry.size.width * 0.77, 360))
                    .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.88)
                    .opacity(hasAppeared ? 1 : 0)
                    .accessibilityLabel("HN")
                Text("Hussein AI Counter")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.91, green: 0.95, blue: 0.96))
                Spacer()
                Text("Designed By Hussein Najah")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(red: 0.61, green: 0.72, blue: 0.76))
                    .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.045, green: 0.090, blue: 0.135).ignoresSafeArea())
            .onAppear {
                withAnimation(.easeOut(duration: reduceMotion ? 0.01 : 1.0)) {
                    hasAppeared = true
                }
            }
        }
    }
}

struct AppEntryView: View {
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            if !showsSplash {
                HomeView()
                    .transition(.opacity)
            }
            if showsSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            // Wait while the welcome mark gently appears, then reveal the app.
            try? await Task.sleep(nanoseconds: 1_750_000_000)
            withAnimation(.easeOut(duration: 0.34)) {
                showsSplash = false
            }
        }
    }
}
