import AppKit
import SwiftUI
import SwiftData
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    static var modelContainer: ModelContainer = {
        let schema = Schema([IntervalSnapshot.self, DailySnapshot.self])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let viewModel = StatusBarViewModel.shared
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        bindViewModel()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 320)
        popover.behavior = .transient
        popover.animates = true
        let contentView = ContentView(viewModel: viewModel)
            .modelContainer(AppDelegate.modelContainer)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }

    private func bindViewModel() {
        viewModel.$quota
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusBar() }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusBar() }
            .store(in: &cancellables)
    }

    private func updateStatusBar() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }

            if !ConfigService.isConfigured {
                button.title = "N/A"
                return
            }

            if let error = self.viewModel.errorMessage, !error.isEmpty {
                button.title = "⚠️"
                return
            }

            if let quota = self.viewModel.quota {
                let percentage = Int((1 - quota.usagePercentage) * 100)
                button.title = "\(percentage)%"
            } else {
                button.title = "..."
            }
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                viewModel.refresh()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}