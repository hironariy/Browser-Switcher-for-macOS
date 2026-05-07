import BrowserSwitcherCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            Section {
                currentBrowserLabel
            }

            Section {
                Button("Switch to Work Browser") {
                    model.switchToWorkBrowser()
                }
                .keyboardShortcut("e", modifiers: [.control, .option])

                Button("Switch to Personal Browser") {
                    model.switchToPersonalBrowser()
                }
                .keyboardShortcut("s", modifiers: [.control, .option])
            }

            Section("Browsers") {
                ForEach(model.settings.browsers) { browser in
                    Button(browser.displayName) {
                        model.switchToBrowser(browser)
                    }
                }
            }

            if let statusMessage = model.statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                }
            }

            Section {
                SettingsLink()

                Button("Refresh Browsers") {
                    model.refreshBrowsers()
                    model.refreshCurrentDefaultBrowser()
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    private var currentBrowserLabel: some View {
        let currentName = model.currentDefaultBrowser?.displayName ?? "Unknown"
        return Label("Current: \(currentName)", systemImage: model.menuBarSystemImage)
    }
}
