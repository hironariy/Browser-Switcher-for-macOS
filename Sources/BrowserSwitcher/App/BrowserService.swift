import AppKit
import BrowserSwitcherCore
import CoreServices
import Foundation

protocol BrowserService {
    func currentDefaultBrowserBundleIdentifier() -> String?
    func installedBrowsers() -> [Browser]
    func setDefaultBrowser(bundleIdentifier: String) throws
}

enum BrowserServiceError: LocalizedError {
    case failedToSetScheme(String, OSStatus)

    var errorDescription: String? {
        switch self {
        case let .failedToSetScheme(scheme, status):
            "Failed to set default handler for \(scheme). OSStatus: \(status)"
        }
    }
}

struct LaunchServicesBrowserService: BrowserService {
    func currentDefaultBrowserBundleIdentifier() -> String? {
        guard let url = url(for: "https"),
              let applicationURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            return nil
        }

        return Bundle(url: applicationURL)?.bundleIdentifier
    }

    func installedBrowsers() -> [Browser] {
        let identifiers = Set(handlers(for: "http") + handlers(for: "https"))

        return identifiers.compactMap { identifier in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else {
                return nil
            }

            let bundle = Bundle(url: url)
            let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            return Browser(
                displayName: displayName,
                bundleIdentifier: identifier,
                role: role(for: identifier)
            )
        }
        .sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    func setDefaultBrowser(bundleIdentifier: String) throws {
        try setDefaultHandler(for: "http", bundleIdentifier: bundleIdentifier)
        try setDefaultHandler(for: "https", bundleIdentifier: bundleIdentifier)
    }

    private func handlers(for scheme: String) -> [String] {
        guard let url = url(for: scheme) else {
            return []
        }

        return NSWorkspace.shared.urlsForApplications(toOpen: url).compactMap {
            Bundle(url: $0)?.bundleIdentifier
        }
    }

    private func url(for scheme: String) -> URL? {
        URL(string: "\(scheme)://www.example.com")
    }

    private func setDefaultHandler(for scheme: String, bundleIdentifier: String) throws {
        let status = LSSetDefaultHandlerForURLScheme(scheme as CFString, bundleIdentifier as CFString)

        guard status == noErr else {
            throw BrowserServiceError.failedToSetScheme(scheme, status)
        }
    }

    private func role(for bundleIdentifier: String) -> BrowserRole {
        switch bundleIdentifier {
        case "com.microsoft.edgemac":
            .work
        case "com.apple.Safari":
            .personal
        default:
            .other
        }
    }
}
