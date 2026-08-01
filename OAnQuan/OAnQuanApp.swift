import SwiftUI

@main
struct OAnQuanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocalizationManager.shared)
        }
    }
}
