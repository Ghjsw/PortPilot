import Foundation

struct PortInfo: Identifiable, Hashable {
    let id: String           // "\(port)-\(pid)-\(address)"
    let port: UInt16
    let processName: String
    let pid: Int32
    let address: String      // "127.0.0.1", "*", "[::1]"
    let isIPv6: Bool

    var displayAddress: String {
        switch address {
        case "*": return "All Interfaces"
        case "127.0.0.1": return "Localhost"
        case "[::1]": return "Localhost (IPv6)"
        case "[::]": return "All Interfaces (IPv6)"
        default: return address
        }
    }
}
