import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var browsers: [Browser]
    public var workBrowserBundleIdentifier: String?
    public var personalBrowserBundleIdentifier: String?
    public var hotKeys: [HotKeyAction: KeyboardShortcut]
    public var launchAtLogin: Bool
    public var showSuccessNotifications: Bool

    public init(
        browsers: [Browser] = AppSettings.defaultBrowsers,
        workBrowserBundleIdentifier: String? = "com.microsoft.edgemac",
        personalBrowserBundleIdentifier: String? = "com.apple.Safari",
        hotKeys: [HotKeyAction: KeyboardShortcut] = AppSettings.defaultHotKeys,
        launchAtLogin: Bool = true,
        showSuccessNotifications: Bool = false
    ) {
        self.browsers = browsers
        self.workBrowserBundleIdentifier = workBrowserBundleIdentifier
        self.personalBrowserBundleIdentifier = personalBrowserBundleIdentifier
        self.hotKeys = hotKeys
        self.launchAtLogin = launchAtLogin
        self.showSuccessNotifications = showSuccessNotifications
    }

    public static let defaultBrowsers: [Browser] = [
        Browser(displayName: "Safari", bundleIdentifier: "com.apple.Safari", role: .personal),
        Browser(displayName: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", role: .work)
    ]

    public static let defaultHotKeys: [HotKeyAction: KeyboardShortcut] = Dictionary(
        uniqueKeysWithValues: HotKeyAction.allCases.map { ($0, $0.defaultShortcut) }
    )

    public func browser(for role: BrowserRole) -> Browser? {
        let selectedBundleIdentifier: String?

        switch role {
        case .work:
            selectedBundleIdentifier = workBrowserBundleIdentifier
        case .personal:
            selectedBundleIdentifier = personalBrowserBundleIdentifier
        case .other:
            selectedBundleIdentifier = nil
        }

        guard let selectedBundleIdentifier else {
            return nil
        }

        return browsers.first { $0.bundleIdentifier == selectedBundleIdentifier }
    }
}
