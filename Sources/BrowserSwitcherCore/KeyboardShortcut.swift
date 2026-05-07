import Foundation

public enum ShortcutModifier: String, Codable, CaseIterable, Comparable, Sendable {
    case control
    case option
    case shift
    case command

    public static func < (lhs: ShortcutModifier, rhs: ShortcutModifier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public var symbol: String {
        switch self {
        case .control:
            "^"
        case .option:
            "Option"
        case .shift:
            "Shift"
        case .command:
            "Command"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .control:
            0
        case .option:
            1
        case .shift:
            2
        case .command:
            3
        }
    }
}

public struct KeyboardShortcut: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt32
    public var keyDisplay: String
    public var modifiers: Set<ShortcutModifier>

    public init(keyCode: UInt32, keyDisplay: String, modifiers: Set<ShortcutModifier>) {
        self.keyCode = keyCode
        self.keyDisplay = keyDisplay
        self.modifiers = modifiers
    }

    public var displayString: String {
        let modifierText = modifiers.sorted().map(\.symbol).joined(separator: "+")
        if modifierText.isEmpty {
            return keyDisplay
        }

        return "\(modifierText)+\(keyDisplay)"
    }

    public static let workDefault = KeyboardShortcut(
        keyCode: 14,
        keyDisplay: "E",
        modifiers: [.control, .option]
    )

    public static let personalDefault = KeyboardShortcut(
        keyCode: 1,
        keyDisplay: "S",
        modifiers: [.control, .option]
    )
}

public enum HotKeyAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case switchToWork
    case switchToPersonal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .switchToWork:
            "Switch to work browser"
        case .switchToPersonal:
            "Switch to personal browser"
        }
    }

    public var defaultShortcut: KeyboardShortcut {
        switch self {
        case .switchToWork:
            .workDefault
        case .switchToPersonal:
            .personalDefault
        }
    }
}
