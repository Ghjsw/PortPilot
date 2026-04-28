import Foundation
import Combine
import AppKit

class PortListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var groupedPorts: [(PortGroup, [PortInfo])] = []
    @Published var searchText: String = ""
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var showKillConfirmation: Bool = false
    @Published var portToKill: PortInfo?
    @Published var showSettings: Bool = false

    // MARK: - Settings

    @Published var refreshInterval: TimeInterval = Constants.Defaults.refreshInterval {
        didSet { restartAutoRefresh() }
    }
    @Published var excludeSystemPorts: Bool = true {
        didSet { refreshPorts() }
    }
    @Published var excludedPorts: Set<UInt16> = [] {
        didSet { refreshPorts() }
    }

    // MARK: - Private

    private var allPorts: [PortInfo] = []
    private let scanner = PortScanner()
    private let killer = ProcessKiller()
    private let classifier = PortGroupClassifier()
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupSearchBinding()
        // Delay first scan to avoid blocking during popover initialization
        DispatchQueue.main.async { [weak self] in
            self?.refreshPorts()
        }
        startAutoRefresh()
    }

    // MARK: - Public Methods

    func refreshPorts() {
        Task { @MainActor in
            isRefreshing = true
            defer { isRefreshing = false }

            do {
                let scanned = try await scanner.scan()
                self.allPorts = applyFilters(scanned)
                self.updateGroupedPorts()
                self.errorMessage = nil
            } catch {
                self.errorMessage = "Scan failed: \(error.localizedDescription)"
            }
        }
    }

    func killPort(_ port: PortInfo, force: Bool = false) {
        Task { @MainActor in
            let result = await killer.kill(pid: port.pid, force: force)
            switch result {
            case .success, .alreadyTerminated:
                try? await Task.sleep(nanoseconds: 500_000_000)
                refreshPorts()
            case .permissionDenied:
                errorMessage = "Permission denied: cannot kill PID \(port.pid)"
            case .failure(let msg):
                errorMessage = "Failed to kill PID \(port.pid): \(msg)"
            }
        }
    }

    func killAllPorts() {
        let allPids = Array(Set(allPorts.map { $0.pid }))
        Task { @MainActor in
            let results = await killer.killAll(pids: allPids)
            let failures = results.filter { !$0.value.isSuccess }
            if !failures.isEmpty {
                errorMessage = "Failed to kill \(failures.count) process(es)"
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshPorts()
        }
    }

    func copyPortNumber(_ port: UInt16) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(String(port), forType: .string)
    }

    func openInBrowser(_ port: UInt16) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    func confirmKill(_ port: PortInfo) {
        portToKill = port
        showKillConfirmation = true
    }

    func executeConfirmedKill() {
        guard let port = portToKill else { return }
        killPort(port)
        portToKill = nil
    }

    // MARK: - Private Methods

    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateGroupedPorts()
            }
            .store(in: &cancellables)
    }

    private func applyFilters(_ ports: [PortInfo]) -> [PortInfo] {
        var filtered = ports
        if excludeSystemPorts {
            filtered = filtered.filter { classifier.classify($0) != .system }
        }
        if !excludedPorts.isEmpty {
            filtered = filtered.filter { !excludedPorts.contains($0.port) }
        }
        return filtered
    }

    private func updateGroupedPorts() {
        let filtered: [PortInfo]
        if searchText.isEmpty {
            filtered = allPorts
        } else {
            let query = searchText.lowercased()
            filtered = allPorts.filter {
                String($0.port).contains(query) ||
                $0.processName.lowercased().contains(query) ||
                String($0.pid).contains(query)
            }
        }

        var groups: [PortGroup: [PortInfo]] = [:]
        for port in filtered {
            let group = classifier.classify(port)
            groups[group, default: []].append(port)
        }

        groupedPorts = PortGroup.allCases
            .filter { groups[$0] != nil }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { ($0, groups[$0]!.sorted { $0.port < $1.port }) }
    }

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        guard refreshInterval.isFinite else { return }
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.refreshPorts()
        }
    }

    func restartAutoRefresh() {
        startAutoRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - KillResult helper

private extension ProcessKiller.KillResult {
    var isSuccess: Bool {
        switch self {
        case .success, .alreadyTerminated: return true
        case .permissionDenied, .failure: return false
        }
    }
}
