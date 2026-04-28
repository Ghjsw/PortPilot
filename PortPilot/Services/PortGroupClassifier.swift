import Foundation

class PortGroupClassifier {

    /// Classify a port into a group
    func classify(_ portInfo: PortInfo) -> PortGroup {
        let processName = portInfo.processName.lowercased()
        let port = portInfo.port

        // 1. Process name exact match (highest priority)
        if isCloudflareProcess(processName) { return .cloudflareTunnel }
        if isK8sProcess(processName) { return .k8sPortForward }
        if isDockerProcess(processName) { return .docker }
        if isLocalDevProcess(processName) { return .localDev }
        if isSystemProcess(processName) { return .system }

        // 2. Well-known port match
        if isSystemPort(port) { return .system }
        if isLocalDevPort(port) { return .localDev }

        // 3. Port range heuristics
        if isEphemeralPort(port) && isLikelySystemProcess(processName) {
            return .system
        }

        return .other
    }

    // MARK: - Cloudflare

    private func isCloudflareProcess(_ name: String) -> Bool {
        return name.contains("cloudflared") || name.contains("cloudflare")
    }

    // MARK: - Kubernetes

    private func isK8sProcess(_ name: String) -> Bool {
        return name.contains("kubectl") ||
               name.hasPrefix("k8s") ||
               name.contains("kube-proxy") ||
               name.contains("kubelet")
    }

    // MARK: - Docker

    private func isDockerProcess(_ name: String) -> Bool {
        return name.contains("docker") ||
               name.contains("containerd") ||
               name.contains("com.docker") ||
               name.contains("vpnkit")
    }

    // MARK: - Local Dev

    private let localDevProcesses: Set<String> = [
        "node", "python", "python3", "ruby", "rails", "puma",
        "java", "dotnet", "php", "nginx", "apache2", "httpd",
        "uvicorn", "gunicorn", "flask", "django", "webpack",
        "vite", "next-server", "remix", "postgres", "mysqld",
        "redis-server", "mongod", "mongos", "elasticsearch",
        "memcached", "rabbitmq", "celery", "go", "air",
        "fresh", "reflex", "realize", "gin", "echo",
        "jupyter", "notebook", "streamlit", "gradio",
    ]

    private func isLocalDevProcess(_ name: String) -> Bool {
        return localDevProcesses.contains(name)
    }

    private func isLocalDevPort(_ port: UInt16) -> Bool {
        let devPorts: Set<UInt16> = [
            3000, 3001, 4000, 4001, 5001, 5173, 5174,
            5500, 5501, 8000, 8001, 8080, 8081, 8443,
            8888, 9000, 9001, 9090, 9222, 19000, 19001,
            4200, 4201, 4400, 4401, 3306, 5432, 6379,
            27017, 5672, 9200, 11211,
        ]
        return devPorts.contains(port)
    }

    // MARK: - System

    private let systemProcesses: Set<String> = [
        "rapportd", "controlcenter", "sharingd", "identityservicesd",
        "nsurlsessiond", "nsurlstoraged", "systemuiserver",
        "loginwindow", "windowserver", "kernel", "launchd",
        "sshd", "ssh", "cron", "cupsd", "mdnsresponder",
        "configd", "syslogd", "distnoted", "secinitd",
    ]

    private func isSystemProcess(_ name: String) -> Bool {
        return systemProcesses.contains(name)
    }

    private func isSystemPort(_ port: UInt16) -> Bool {
        let systemPorts: Set<UInt16> = [
            22, 80, 443, 548, 631, 88, 749, 5000, 7000,
        ]
        return systemPorts.contains(port)
    }

    private func isLikelySystemProcess(_ name: String) -> Bool {
        return systemProcesses.contains(where: { name.contains($0) })
    }

    private func isEphemeralPort(_ port: UInt16) -> Bool {
        return port >= 49152
    }
}
