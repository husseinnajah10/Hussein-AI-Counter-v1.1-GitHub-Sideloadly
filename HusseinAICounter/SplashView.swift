import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        GeometryReader { bounds in
            ZStack {
                LinearGradient(colors: [Color(red: 0.16, green: 0.10, blue: 0.035),
                                        Color(red: 0.45, green: 0.29, blue: 0.09),
                                        Color(red: 0.11, green: 0.13, blue: 0.09),
                                        GoldTeal.background],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Circle().fill(GoldTeal.gold.opacity(0.13))
                    .frame(width: 330, height: 330).blur(radius: 70).offset(y: -100)
                VStack(spacing: 12) {
                    Spacer()
                    Image("GoldenGate")
                        .resizable().scaledToFit()
                        .frame(width: min(bounds.size.width * 0.91, 460))
                        .scaleEffect(visible || reduceMotion ? 1 : 0.87)
                        .opacity(visible ? 1 : 0)
                        .accessibilityLabel("Golden Gate")
                    Text("Student AI Counter")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GoldTeal.goldLight)
                    Text("Golden Gate")
                        .font(.subheadline).foregroundStyle(GoldTeal.subtle)
                    Spacer()
                    CreditFooter().padding(.bottom, 18)
                }
                .padding(.horizontal, 22)
            }
            .onAppear {
                withAnimation(.easeOut(duration: reduceMotion ? 0.01 : 0.9)) {
                    visible = true
                }
            }
        }
    }
}

struct AppEntryView: View {
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            if !showsSplash { HomeView().transition(.opacity) }
            if showsSplash { SplashView().transition(.opacity) }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_750_000_000)
            withAnimation(.easeInOut(duration: 0.28)) { showsSplash = false }
        }
    }
}
