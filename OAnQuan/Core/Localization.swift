import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, vi
    var id: String { rawValue }
    var displayName: String { self == .en ? "English" : "Tiếng Việt" }
}

/// Manual bundle-swap localizer so the in-app language can change at runtime
/// without relaunching (system Locale-driven Text() only picks up the language
/// on next app launch, which isn't enough for an in-app switcher).
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
            // Without this, setting `language` directly (e.g. the segmented
            // Picker on HomeView binding straight to `$loc.language`) only
            // updated the published enum, not the resolved lookup bundle —
            // so `L()` kept returning the old language's strings until the
            // next app relaunch, silently defeating the whole point of this
            // manual bundle-swap localizer. `setLanguage(_:)` below already
            // did this correctly but was only reachable via the DEBUG
            // OQ_LANG launch-arg path used for screenshot automation, never
            // from the real in-app switcher.
            bundle = Self.bundle(for: language)
        }
    }

    private var bundle: Bundle = .main

    init() {
        let stored = UserDefaults.standard.string(forKey: "app_language")
        let lang = AppLanguage(rawValue: stored ?? "") ?? Self.systemDefault()
        self.language = lang
        self.bundle = Self.bundle(for: lang)
    }

    private static func systemDefault() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("vi") ? .vi : .en
    }

    private static func bundle(for lang: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
              let b = Bundle(path: path) else { return .main }
        return b
    }

    /// Thin wrapper kept for call-site clarity (DEBUG OQ_LANG launch-arg
    /// path). `language`'s didSet now does the actual bundle swap, so a
    /// plain `language = lang` assignment (as the in-app Picker does) works
    /// identically.
    func setLanguage(_ lang: AppLanguage) {
        language = lang
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Shorthand: L("home.title") looks up the current in-app language, live.
func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}
