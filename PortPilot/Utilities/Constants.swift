import Foundation

enum Constants {
    static let appName = "PortPilot"
    static let bundleIdentifier = "com.portpilot.app"

    enum Defaults {
        static let refreshInterval: TimeInterval = 5.0
        static let popoverWidth: CGFloat = 380
        static let popoverHeight: CGFloat = 520
        static let killTimeout: TimeInterval = 3.0
        static let killPollIntervalNs: UInt64 = 100_000_000 // 100ms
    }

    enum Lsof {
        static let path = "/usr/sbin/lsof"
        static let arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]
    }
}
