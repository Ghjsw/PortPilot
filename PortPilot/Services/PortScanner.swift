import Foundation

class PortScanner {

    func scan() async throws -> [PortInfo] {
        let output = try await runLsof()
        return parseLsofOutput(output)
    }

    private func runLsof() async throws -> String {
        // Run lsof on a background thread to avoid blocking the main thread
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipe = Pipe()
            let errPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: Constants.Lsof.path)
            process.arguments = Constants.Lsof.arguments
            process.standardOutput = pipe
            process.standardError = errPipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }

    private func parseLsofOutput(_ output: String) -> [PortInfo] {
        var ports: [PortInfo] = []
        var seen = Set<String>()

        let lines = output.components(separatedBy: "\n")
        for line in lines.dropFirst() {
            guard let info = parseLine(line) else { continue }
            let key = info.id
            if seen.insert(key).inserted {
                ports.append(info)
            }
        }

        return ports.sorted { $0.port < $1.port }
    }

    private func parseLine(_ line: String) -> PortInfo? {
        // lsof output: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
        // Example: Google  487 gonghe  387u  IPv4 0x123 0t0  TCP 127.0.0.1:9222 (LISTEN)
        // The NAME field is after "TCP" keyword, format: host:port or *:port or [::1]:port

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let fields = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count >= 9 else { return nil }

        let command = String(fields[0])
        guard let pid = Int32(fields[1]) else { return nil }

        // Find the field after "TCP" keyword - this is the most reliable approach
        guard let tcpIndex = fields.lastIndex(where: { String($0) == "TCP" }),
              tcpIndex + 1 < fields.count else { return nil }

        let nameField = String(fields[tcpIndex + 1])
        return parseAddressPort(nameField, command: command, pid: pid)
    }

    private func parseAddressPort(_ nameField: String, command: String, pid: Int32) -> PortInfo? {
        // Strip "(LISTEN)" suffix if present
        let cleaned = nameField.replacingOccurrences(of: "(LISTEN)", with: "")
                               .trimmingCharacters(in: .whitespaces)

        let isIPv6 = cleaned.hasPrefix("[")

        let addressPart: String
        let portPart: String

        if isIPv6 {
            // [::1]:42050 or [::]:8080
            guard let closeBracket = cleaned.firstIndex(of: "]") else { return nil }
            addressPart = String(cleaned[...closeBracket])
            let afterBracket = cleaned[cleaned.index(after: closeBracket)...]
            portPart = afterBracket.hasPrefix(":") ? String(afterBracket.dropFirst()) : ""
        } else {
            // 127.0.0.1:9222 or *:49194
            let parts = cleaned.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            addressPart = String(parts[0])
            portPart = String(parts[1])
        }

        guard let port = UInt16(portPart), port > 0 else { return nil }

        let id = "\(port)-\(pid)-\(addressPart)"
        return PortInfo(
            id: id,
            port: port,
            processName: command,
            pid: pid,
            address: addressPart,
            isIPv6: isIPv6
        )
    }
}
