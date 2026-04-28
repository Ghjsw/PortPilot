import SwiftUI

enum PortGroup: String, CaseIterable, Identifiable {
    case cloudflareTunnel = "Cloudflare Tunnels"
    case k8sPortForward = "K8s Port Forward"
    case docker = "Docker"
    case localDev = "Local Dev"
    case system = "System"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cloudflareTunnel: return "cloud.fill"
        case .k8sPortForward:   return "arrow.triangle.branch"
        case .docker:           return "shippingbox.fill"
        case .localDev:         return "hammer.fill"
        case .system:           return "gearshape.fill"
        case .other:            return "questionmark.folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .cloudflareTunnel: return .orange
        case .k8sPortForward:   return .blue
        case .docker:           return .cyan
        case .localDev:         return .green
        case .system:           return .gray
        case .other:            return .secondary
        }
    }

    var sortOrder: Int {
        switch self {
        case .cloudflareTunnel: return 0
        case .k8sPortForward:   return 1
        case .docker:           return 2
        case .localDev:         return 3
        case .system:           return 4
        case .other:            return 5
        }
    }
}
