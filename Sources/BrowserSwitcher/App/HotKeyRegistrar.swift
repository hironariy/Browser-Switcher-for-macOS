import BrowserSwitcherCore
import Carbon
import Foundation

protocol HotKeyRegistrar {
    func register(shortcut: KeyboardShortcut, action: HotKeyAction, handler: @escaping () -> Void) throws
    func unregisterAll()
}

enum HotKeyRegistrarError: LocalizedError {
    case registrationFailed(OSStatus)
    case handlerInstallFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .registrationFailed(status):
            "Hot key registration failed. OSStatus: \(status)"
        case let .handlerInstallFailed(status):
            "Hot key event handler could not be installed. OSStatus: \(status)"
        }
    }
}

final class CarbonHotKeyRegistrar: HotKeyRegistrar {
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var handlers: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?

    deinit {
        unregisterAll()
    }

    func register(shortcut: KeyboardShortcut, action: HotKeyAction, handler: @escaping () -> Void) throws {
        try installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: fourCharacterCode("DBSW"), id: UInt32(actionIndex(for: action)))
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            throw HotKeyRegistrarError.registrationFailed(status)
        }

        hotKeyRefs.append(hotKeyRef)
        handlers[hotKeyID.id] = handler
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }

        hotKeyRefs.removeAll()
        handlers.removeAll()
    }

    private func installHandlerIfNeeded() throws {
        guard eventHandlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let registrar = Unmanaged<CarbonHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
                registrar.handlers[hotKeyID.id]?()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        guard status == noErr else {
            throw HotKeyRegistrarError.handlerInstallFailed(status)
        }
    }

    private func actionIndex(for action: HotKeyAction) -> Int {
        switch action {
        case .switchToWork:
            1
        case .switchToPersonal:
            2
        }
    }

    private func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}

private extension KeyboardShortcut {
    var carbonModifiers: UInt32 {
        modifiers.reduce(0) { result, modifier in
            switch modifier {
            case .control:
                result | UInt32(controlKey)
            case .option:
                result | UInt32(optionKey)
            case .shift:
                result | UInt32(shiftKey)
            case .command:
                result | UInt32(cmdKey)
            }
        }
    }
}
