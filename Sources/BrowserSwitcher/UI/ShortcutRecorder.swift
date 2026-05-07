import AppKit
import BrowserSwitcherCore
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    var shortcut: BrowserSwitcherCore.KeyboardShortcut?
    var onChange: (BrowserSwitcherCore.KeyboardShortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.onShortcutChange = onChange
        button.shortcut = shortcut
        return button
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.onShortcutChange = onChange
        nsView.shortcut = shortcut
    }
}

final class ShortcutRecorderButton: NSButton {
    var onShortcutChange: ((BrowserSwitcherCore.KeyboardShortcut) -> Void)?

    var shortcut: BrowserSwitcherCore.KeyboardShortcut? {
        didSet {
            title = shortcut?.displayString ?? "Record Shortcut"
        }
    }

    private var isRecording = false {
        didSet {
            title = isRecording ? "Press keys..." : shortcut?.displayString ?? "Record Shortcut"
            bezelColor = isRecording ? .controlAccentColor : nil
        }
    }

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(startRecording)
        focusRingType = .default
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    @objc private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let modifiers = ShortcutModifier.modifiers(from: event.modifierFlags)
        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }

        let shortcut = BrowserSwitcherCore.KeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            keyDisplay: Self.displayName(for: event),
            modifiers: modifiers
        )

        self.shortcut = shortcut
        onShortcutChange?(shortcut)
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    private static func displayName(for event: NSEvent) -> String {
        if event.keyCode == 49 {
            return "Space"
        }

        return event.charactersIgnoringModifiers?
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            ?? "Key \(event.keyCode)"
    }
}

private extension ShortcutModifier {
    static func modifiers(from flags: NSEvent.ModifierFlags) -> Set<ShortcutModifier> {
        var modifiers: Set<ShortcutModifier> = []

        if flags.contains(.control) {
            modifiers.insert(.control)
        }

        if flags.contains(.option) {
            modifiers.insert(.option)
        }

        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }

        if flags.contains(.command) {
            modifiers.insert(.command)
        }

        return modifiers
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
