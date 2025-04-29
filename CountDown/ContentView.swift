import SwiftUI
import UserNotifications
import AppKit

struct ContentView: View {
    @EnvironmentObject private var timerModel: TimerModel
    @State private var isPresentingSettings = false
    
    var body: some View {
        ZStack {
            // Background with custom color and opacity
            timerModel.backgroundColor
                .opacity(timerModel.backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                TimerView()
                StatusView()
                TimerInputView()
                TimerControlsView(isPresentingSettings: $isPresentingSettings)
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
                .environmentObject(timerModel)
        }
        .frame(width: 150)
        .windowLevel(alwaysOnTop: $timerModel.windowAlwaysOnTop)
    }
}

// Preview for development
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TimerModel())
            .preferredColorScheme(.dark)
    }
}
