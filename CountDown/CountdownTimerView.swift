import SwiftUI
import UserNotifications
import AppKit
import Observation

struct CountdownTimerView: View {
    @Environment(TimerModel.self) private var timerModel
    @State private var isPresentingSettings = false
    
    var body: some View {
        @Bindable var timerModel = timerModel

        ZStack {
            // Background with custom color and opacity
            timerModel.backgroundColor
                .opacity(timerModel.backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 4) {
                TimerView()
                StatusView()
                TimerInputView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                TimerControlsView(isPresentingSettings: $isPresentingSettings)
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
        .frame(width: 150)
        .windowLevel(alwaysOnTop: $timerModel.windowAlwaysOnTop)
    }
}

// Preview for development
struct CountdownTimerView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownTimerView()
            .environment(TimerModel())
            .preferredColorScheme(.dark)
    }
}
