import AppKit
import BrowserSwitcherCore
import Combine
import Foundation
import ServiceManagement
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var currentDefaultBrowserBundleIdentifier: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var hotKeyStatusMessage: String?

    private let browserService: BrowserService
    private let settingsStore: SettingsStore
    private let hotKeyRegistrar: HotKeyRegistrar
    private var cancellables: Set<AnyCancellable> = []

    init(
        browserService: BrowserService = LaunchServicesBrowserService(),
        settingsStore: SettingsStore = UserDefaultsSettingsStore(),
        hotKeyRegistrar: HotKeyRegistrar = CarbonHotKeyRegistrar()
    ) {
        self.browserService = browserService
        self.settingsStore = settingsStore
        self.hotKeyRegistrar = hotKeyRegistrar
        self.settings = settingsStore.load()

        refreshBrowsers()
        refreshCurrentDefaultBrowser()
        registerHotKeys()
        applyLoginItemPreference()
    }

    var menuBarSystemImage: String {
        guard let currentDefaultBrowserBundleIdentifier else {
            return "globe"
        }

        if currentDefaultBrowserBundleIdentifier == settings.workBrowserBundleIdentifier {
            return "briefcase"
        }

        if currentDefaultBrowserBundleIdentifier == settings.personalBrowserBundleIdentifier {
            return "person"
        }

        return "globe"
    }

    var currentDefaultBrowser: Browser? {
        guard let currentDefaultBrowserBundleIdentifier else {
            return nil
        }

        return settings.browsers.first { $0.bundleIdentifier == currentDefaultBrowserBundleIdentifier }
    }

    func refreshBrowsers() {
        let installedBrowsers = browserService.installedBrowsers()
        var mergedByIdentifier = Dictionary(uniqueKeysWithValues: settings.browsers.map { ($0.bundleIdentifier, $0) })

        for browser in installedBrowsers {
            if var existing = mergedByIdentifier[browser.bundleIdentifier] {
                existing.displayName = browser.displayName
                mergedByIdentifier[browser.bundleIdentifier] = existing
            } else {
                mergedByIdentifier[browser.bundleIdentifier] = browser
            }
        }

        settings.browsers = mergedByIdentifier.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        persistSettings(reloadHotKeys: false)
    }

    func refreshCurrentDefaultBrowser() {
        currentDefaultBrowserBundleIdentifier = browserService.currentDefaultBrowserBundleIdentifier()
    }

    func setWorkBrowser(_ browser: Browser) {
        settings.workBrowserBundleIdentifier = browser.bundleIdentifier
        assignRole(.work, to: browser.bundleIdentifier)
        persistSettings()
    }

    func setPersonalBrowser(_ browser: Browser) {
        settings.personalBrowserBundleIdentifier = browser.bundleIdentifier
        assignRole(.personal, to: browser.bundleIdentifier)
        persistSettings()
    }

    func setShortcut(_ shortcut: KeyboardShortcut, for action: HotKeyAction) {
        settings.hotKeys[action] = shortcut
        persistSettings()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled
        persistSettings(reloadHotKeys: false)
        applyLoginItemPreference()
    }

    func setShowSuccessNotifications(_ enabled: Bool) {
        settings.showSuccessNotifications = enabled
        persistSettings(reloadHotKeys: false)

        if enabled {
            requestNotificationPermission()
        }
    }

    func switchToWorkBrowser() {
        guard let browser = settings.browser(for: .work) else {
            reportFailure("Work browser is not configured.")
            return
        }

        switchToBrowser(browser)
    }

    func switchToPersonalBrowser() {
        guard let browser = settings.browser(for: .personal) else {
            reportFailure("Personal browser is not configured.")
            return
        }

        switchToBrowser(browser)
    }

    func switchToBrowser(_ browser: Browser) {
        do {
            try browserService.setDefaultBrowser(bundleIdentifier: browser.bundleIdentifier)
            currentDefaultBrowserBundleIdentifier = browser.bundleIdentifier
            reportSuccess("Default browser changed to \(browser.displayName).")

            Task { @MainActor in
                await verifyDefaultBrowserChange(to: browser)
            }
        } catch {
            reportFailure(error.localizedDescription)
        }
    }

    private func assignRole(_ role: BrowserRole, to bundleIdentifier: String) {
        settings.browsers = settings.browsers.map { browser in
            var updated = browser

            if browser.bundleIdentifier == bundleIdentifier {
                updated.role = role
            } else if browser.role == role {
                updated.role = .other
            }

            return updated
        }
    }

    private func persistSettings(reloadHotKeys: Bool = true) {
        settingsStore.save(settings)

        if reloadHotKeys {
            registerHotKeys()
        }
    }

    private func registerHotKeys() {
        hotKeyRegistrar.unregisterAll()
        hotKeyStatusMessage = nil

        for action in HotKeyAction.allCases {
            guard let shortcut = settings.hotKeys[action] else {
                continue
            }

            do {
                try hotKeyRegistrar.register(shortcut: shortcut, action: action) { [weak self] in
                    Task { @MainActor in
                        self?.perform(action)
                    }
                }
            } catch {
                hotKeyStatusMessage = "Could not register \(shortcut.displayString): \(error.localizedDescription)"
            }
        }
    }

    private func perform(_ action: HotKeyAction) {
        switch action {
        case .switchToWork:
            switchToWorkBrowser()
        case .switchToPersonal:
            switchToPersonalBrowser()
        }
    }

    private func applyLoginItemPreference() {
        guard #available(macOS 13.0, *) else {
            statusMessage = "Login item requires macOS 13 or later."
            return
        }

        do {
            if settings.launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            statusMessage = "Could not update login item: \(error.localizedDescription)"
        }
    }

    private func reportSuccess(_ message: String) {
        statusMessage = message

        if settings.showSuccessNotifications {
            sendSuccessNotification(message)
        }
    }

    private func reportFailure(_ message: String) {
        statusMessage = message
        NSSound.beep()
    }

    private func verifyDefaultBrowserChange(to browser: Browser) async {
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 150_000_000)
            let actualBrowserBundleIdentifier = browserService.currentDefaultBrowserBundleIdentifier()

            if actualBrowserBundleIdentifier == browser.bundleIdentifier {
                currentDefaultBrowserBundleIdentifier = actualBrowserBundleIdentifier
                return
            }
        }

        let actualBrowserBundleIdentifier = browserService.currentDefaultBrowserBundleIdentifier()
        reportFailure("macOS accepted the request, but the default browser still appears to be \(actualBrowserBundleIdentifier ?? "unknown").")
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendSuccessNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Browser Switcher"
        content.body = message

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
