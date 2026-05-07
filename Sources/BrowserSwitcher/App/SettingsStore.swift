import BrowserSwitcherCore
import Foundation

protocol SettingsStore {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

struct UserDefaultsSettingsStore: SettingsStore {
    private let key = "browserSwitcher.settings.v1"
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppSettings {
        guard let data = userDefaults.data(forKey: key) else {
            return AppSettings()
        }

        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            return AppSettings()
        }
    }

    func save(_ settings: AppSettings) {
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to encode settings: \(error)")
        }
    }
}
