import Foundation

class ProcessKiller {

    enum KillResult: Equatable {
        case success
        case alreadyTerminated
        case permissionDenied
        case failure(String)
    }

    /// Kill a process. If force is false, sends SIGTERM first, then escalates to SIGKILL after timeout.
    func kill(pid: Int32, force: Bool = false) async -> KillResult {
        if force {
            return sendSignal(SIGKILL, to: pid)
        }

        // Try SIGTERM first
        let termResult = sendSignal(SIGTERM, to: pid)
        switch termResult {
        case .success:
            // Wait for process to exit
            let exited = await waitForExit(pid: pid, timeout: Constants.Defaults.killTimeout)
            if exited {
                return .success
            }
            // Timeout - escalate to SIGKILL
            return sendSignal(SIGKILL, to: pid)
        case .alreadyTerminated:
            return .alreadyTerminated
        default:
            return termResult
        }
    }

    /// Kill multiple processes concurrently
    func killAll(pids: [Int32]) async -> [Int32: KillResult] {
        await withTaskGroup(of: (Int32, KillResult).self) { group in
            for pid in pids {
                group.addTask { (pid, await self.kill(pid: pid)) }
            }
            var results: [Int32: KillResult] = [:]
            for await (pid, result) in group {
                results[pid] = result
            }
            return results
        }
    }

    private func sendSignal(_ signal: Int32, to pid: Int32) -> KillResult {
        // Check if process exists first (signal 0)
        if Darwin.kill(pid, 0) != 0 {
            let err = errno
            if err == ESRCH { return .alreadyTerminated }
            if err == EPERM { return .permissionDenied }
            return .failure(String(cString: strerror(err)))
        }

        // Send the actual signal
        if Darwin.kill(pid, signal) != 0 {
            let err = errno
            if err == ESRCH { return .alreadyTerminated }
            if err == EPERM { return .permissionDenied }
            return .failure(String(cString: strerror(err)))
        }

        return .success
    }

    private func waitForExit(pid: Int32, timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if Darwin.kill(pid, 0) != 0 && errno == ESRCH {
                return true
            }
            try? await Task.sleep(nanoseconds: Constants.Defaults.killPollIntervalNs)
        }
        return false
    }
}
