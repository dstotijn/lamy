import Foundation

public final class DarwinNotificationCenter: Sendable {
    public static let shared = DarwinNotificationCenter()

    nonisolated(unsafe) private let center: CFNotificationCenter

    private init() {
        center = CFNotificationCenterGetDarwinNotifyCenter()
    }

    public func post(_ name: String) {
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: name as CFString),
            nil,
            nil,
            true
        )
    }

    public func observe(
        _ name: String,
        callback: @escaping @Sendable () -> Void
    ) {
        let observer = Unmanaged.passRetained(
            CallbackBox(callback: callback)
        ).toOpaque()

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let box = Unmanaged<CallbackBox>.fromOpaque(observer)
                    .takeUnretainedValue()
                box.callback()
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }
}

private final class CallbackBox: Sendable {
    let callback: @Sendable () -> Void
    init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }
}
