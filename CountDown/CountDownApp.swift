import SwiftUI
import ServiceManagement

@main
struct CountDownApp: App {
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
}
