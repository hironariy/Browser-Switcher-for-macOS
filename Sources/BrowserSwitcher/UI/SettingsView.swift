import BrowserSwitcherCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            browserSettings
                .tabItem {
                    Label("Browsers", systemImage: "globe")
                }

            shortcutSettings
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            appSettings
                .tabItem {
                    Label("App", systemImage: "gearshape")
                }
        }
        .padding(20)
    }

    private var browserSettings: some View {
        Form {
            Picker("Work browser", selection: workBrowserBinding) {
                ForEach(model.settings.browsers) { browser in
                    Text(browser.displayName).tag(Optional(browser.bundleIdentifier))
                }
            }

            Picker("Personal browser", selection: personalBrowserBinding) {
                ForEach(model.settings.browsers) { browser in
                    Text(browser.displayName).tag(Optional(browser.bundleIdentifier))
                }
            }

            Divider()

            List(model.settings.browsers) { browser in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(browser.displayName)
                        Text(browser.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(browser.role.displayName)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 220)

            Button("Refresh Installed Browsers") {
                model.refreshBrowsers()
                model.refreshCurrentDefaultBrowser()
            }
        }
    }

    private var shortcutSettings: some View {
        Form {
            ForEach(HotKeyAction.allCases, id: \.id) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(action.displayName)
                        Text(model.settings.hotKeys[action]?.displayString ?? "Not set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ShortcutRecorder(shortcut: model.settings.hotKeys[action]) { shortcut in
                        model.setShortcut(shortcut, for: action)
                    }
                    .frame(width: 190, height: 34)
                }
            }

            if let hotKeyStatusMessage = model.hotKeyStatusMessage {
                Text(hotKeyStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var appSettings: some View {
        Form {
            Toggle("Launch at login", isOn: launchAtLoginBinding)
            Toggle("Show success notifications", isOn: showSuccessNotificationsBinding)

            Divider()

            if let statusMessage = model.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var workBrowserBinding: Binding<String?> {
        Binding(
            get: { model.settings.workBrowserBundleIdentifier },
            set: { bundleIdentifier in
                guard
                    let bundleIdentifier,
                    let browser = model.settings.browsers.first(where: { $0.bundleIdentifier == bundleIdentifier })
                else {
                    return
                }

                model.setWorkBrowser(browser)
            }
        )
    }

    private var personalBrowserBinding: Binding<String?> {
        Binding(
            get: { model.settings.personalBrowserBundleIdentifier },
            set: { bundleIdentifier in
                guard
                    let bundleIdentifier,
                    let browser = model.settings.browsers.first(where: { $0.bundleIdentifier == bundleIdentifier })
                else {
                    return
                }

                model.setPersonalBrowser(browser)
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.settings.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        )
    }

    private var showSuccessNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.settings.showSuccessNotifications },
            set: { model.setShowSuccessNotifications($0) }
        )
    }
}
