import Foundation

public enum LamyConstants {
    public static let appGroupID = "group.com.dstotijn.lamy"
    public static let urlScheme = "lamy"

    public enum DarwinNotification {
        public static let stateChanged = "com.dstotijn.lamy.stateChanged"
    }

    public enum SharedKey {
        public static let state = "transcriptionState"
    }

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID)!
    }

    public static var sharedContainerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )!
    }

    public static var audioFileURL: URL {
        sharedContainerURL.appendingPathComponent("recording.m4a")
    }
}
