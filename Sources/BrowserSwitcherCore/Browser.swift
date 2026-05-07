import Foundation

public enum BrowserRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case work
    case personal
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .work:
            "Work"
        case .personal:
            "Personal"
        case .other:
            "Other"
        }
    }
}

public struct Browser: Codable, Equatable, Identifiable, Sendable {
    public var id: String { bundleIdentifier }

    public var displayName: String
    public var bundleIdentifier: String
    public var role: BrowserRole

    public init(displayName: String, bundleIdentifier: String, role: BrowserRole = .other) {
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.role = role
    }
}
