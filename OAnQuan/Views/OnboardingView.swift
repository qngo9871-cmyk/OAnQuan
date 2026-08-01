import SwiftUI

/// Four-page first-launch walkthrough: the board layout, picking up and
/// sowing, the capture ("ăn") chain, and forced borrowing ("mượn") plus
/// scoring. Shown once, and re-accessible from Home and from in-game via
/// "How to Play".
struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page: Int = {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["OQ_ONBOARDING_PAGE"], let p = Int(raw) { return p }
        #endif
        return 0
    }()

    private let pageKeys: [(title: String, body: String)] = [
        ("onboarding.page1.title", "onboarding.page1.body"),
        ("onboarding.page2.title", "onboarding.page2.body"),
        ("onboarding.page3.title", "onboarding.page3.body"),
        ("onboarding.page4.title", "onboarding.page4.body"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(L(pageKeys[page].title))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(L(pageKeys[page].body))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            HStack(spacing: 8) {
                ForEach(pageKeys.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            Button(action: advance) {
                Text(page == pageKeys.count - 1 ? L("onboarding.begin") : L("onboarding.next"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 36)
            .padding(.bottom, 50)
        }
        .animation(.easeInOut, value: page)
    }

    private func advance() {
        if page < pageKeys.count - 1 {
            page += 1
        } else {
            onFinished()
        }
    }
}

#Preview { OnboardingView(onFinished: {}) }
