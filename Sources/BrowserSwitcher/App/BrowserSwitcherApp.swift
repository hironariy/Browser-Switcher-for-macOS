import SwiftUI

@main
struct BrowserSwitcherApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(model: model)
        } label: {
            Image(systemName: model.menuBarSystemImage)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(model: model)
                .frame(width: 620, height: 520)
        }
    }
}
