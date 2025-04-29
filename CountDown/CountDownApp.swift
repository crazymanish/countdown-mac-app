import SwiftUI
import ServiceManagement

@main
struct CountDownApp: App {
    @AppStorage("launchAtLogin") private var launchAtLogin = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    private var timerModel = TimerModel()
    
    var body: some Scene {
        WindowGroup {
            CountdownTimerView()
                .environment(timerModel)
                .preferredColorScheme(.none) // Supports both light and dark mode
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Clean window style
        .commands {
            // Add keyboard commands
            CommandGroup(after: .newItem) {
                Button("Reset Timer") {
                    timerModel.resetTimer()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Toggle Play/Pause") {
                    timerModel.toggleTimer()
                }
                .keyboardShortcut(.space, modifiers: [])
            }
            
            // Add a custom settings menu
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    init() {
        // Set up launch at login when the app starts if needed
        updateLaunchAtLogin()
    }
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            // For macOS 13 and later, use the SMAppService API
            let service = SMAppService.mainApp
            do {
                if launchAtLogin {
                    if service.status == .notRegistered {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
            } catch {
                print("Failed to update launch at login status: \(error.localizedDescription)")
            }
        } else {
            // For macOS 12 and earlier, use the legacy API
            // This will show deprecation warnings but will work for older systems
            let url = Bundle.main.bundleURL
            
            if let existingLoginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() {
                if launchAtLogin {
                    LSSharedFileListInsertItemURL(
                        existingLoginItems,
                        kLSSharedFileListItemLast.takeRetainedValue(),
                        nil,
                        nil,
                        url as CFURL,
                        nil,
                        nil
                    )
                } else {
                    if let loginItems = LSSharedFileListCopySnapshot(existingLoginItems, nil)?.takeRetainedValue() as? [LSSharedFileListItem] {
                        for loginItem in loginItems {
                            var resOutURL: Unmanaged<CFURL>?
                            
                            LSSharedFileListItemResolve(loginItem, 0, &resOutURL, nil)
                            
                            if let urlRef = resOutURL?.takeRetainedValue(), 
                               let itemURL = urlRef as URL?,
                               itemURL.path == url.path {
                                LSSharedFileListItemRemove(existingLoginItems, loginItem)
                            }
                        }
                    }
                }
            }
        }
    }
}
