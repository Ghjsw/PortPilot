import AppKit
import SwiftUI

class StatusBarController {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private let viewModel = PortListViewModel()

    init() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // Configure button
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.up.arrow.down.circle.fill",
                                   accessibilityDescription: "PortPilot")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover with SwiftUI content
        let contentView = PortListView(viewModel: viewModel)

        popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.Defaults.popoverWidth,
                                     height: Constants.Defaults.popoverHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        // Monitor global clicks to close popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePopoverIfNeeded()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Refresh when showing
        viewModel.refreshPorts()
    }

    private func closePopoverIfNeeded() {
        guard popover.isShown else { return }
        popover.performClose(nil)
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
