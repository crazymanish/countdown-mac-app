import SwiftUI
import UserNotifications
import AppKit  // Added import for NSWindow access

struct ContentView: View {
    @EnvironmentObject private var timerModel: TimerModel
    @State private var isPresentingSettings = false
    @FocusState private var isInputFieldFocused: Bool
    
    // Animation states
    @State private var isTimerPulsing = false
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        ZStack {
            // Background with custom color and opacity
            timerModel.backgroundColor
                .opacity(timerModel.backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 4) {
                timerView
                statusView
                timerInputView
                timerControlsView
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
                .environmentObject(timerModel)
        }
        .frame(width: 150)
        .windowLevel(alwaysOnTop: $timerModel.windowAlwaysOnTop)
        .onChange(of: timerModel.shouldFocusInput) { oldValue, newValue in
            // Sync FocusState with the TimerModel's shouldFocusInput property
            isInputFieldFocused = newValue
        }
    }

    private var timerView: some View {
        // Timer display (horizontal progress bar instead of circle)
        VStack(spacing: 5) {
            // Time text
            Text(formatTimeHorizontal(timerModel.timeRemaining))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerModel.timeRemaining)
                .scaleEffect(isTimerPulsing ? 1.25 : 1.0)
                .animation(
                    timerModel.isRunning ?
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                    .default,
                    value: isTimerPulsing
                )

            // Horizontal progress bar
            ZStack(alignment: .leading) {
                // Background progress bar
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 8)
                    .cornerRadius(4)

                // Foreground progress bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: timerModel.targetDuration > 0
                            ? CGFloat(timerModel.timeRemaining / timerModel.targetDuration) * 180
                            : 0,
                        height: 8
                    )
                    .cornerRadius(4)
            }
            .frame(width: 180)
            .animation(.easeInOut, value: timerModel.timeRemaining)
        }
        .onAppear {
            isTimerPulsing = timerModel.isRunning
        }
        .onChange(of: timerModel.isRunning) { oldValue, newValue in
            isTimerPulsing = newValue
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var statusView: some View {
        // Status message or completion message (only one shows at a time)
        if (!timerModel.completionMessage.isEmpty) {
            Text(timerModel.completionMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.5))
                )
                .lineLimit(1)
                .transition(.opacity)
                .id("completion-\(timerModel.completionMessage)")
        } else if (!timerModel.statusMessage.isEmpty) {
            Text(timerModel.statusMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .transition(.opacity)
                .id("status-\(timerModel.statusMessage)")
        }
    }

    private var timerInputView: some View {
        HStack(spacing: 2) {
            TextField("Duration (10m, 3pm, 1hr)", text: $timerModel.inputText)
                .font(.system(size: 10))
                .padding([.vertical, .horizontal], 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.05))
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .submitLabel(.done)
                .onSubmit {
                    withAnimation {
                        timerModel.parseInput()
                        isInputFieldFocused = false // Turn off focus after submitting
                    }
                }
                .focused($isInputFieldFocused)
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                    isInputFieldFocused = true
                }
                // Handle keyboard shortcuts
                .onKeyPress(.upArrow) {
                    withAnimation {
                        timerModel.previousHistoryItem()
                    }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    withAnimation {
                        timerModel.nextHistoryItem()
                    }
                    return .handled
                }
                .onKeyPress(.space) {
                    if (!isInputFieldFocused || timerModel.inputText.isEmpty) {
                        withAnimation {
                            timerModel.toggleTimer()
                        }
                        return .handled
                    }
                    return .ignored
                }
                .onTapGesture {
                    isInputFieldFocused = true // Ensure focus when manually tapped
                }

            Button(action: {
                withAnimation {
                    timerModel.parseInput()
                }
            }) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    private var timerControlsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    timerModel.toggleTimer()
                }
            }) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: timerModel.isRunning ? "pause.fill" : "play.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                    )
            }
            .keyboardShortcut(.space, modifiers: [])
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Button(action: {
                withAnimation {
                    rotationDegrees -= 360
                    timerModel.resetTimer()
                }
            }) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.purple)
                            .rotationEffect(.degrees(rotationDegrees))
                    )
            }
            .keyboardShortcut("r", modifiers: .command)
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Spacer()

            Button(action: {
                withAnimation {
                    isPresentingSettings.toggle()
                }
            }) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "gear")
                            .font(.system(size: 12))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.gray)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }

    // Helper functions for time formatting
    private func formatTimeHorizontal(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d\u{202F}h %d\u{202F}m %d\u{202F}s", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d\u{202F}m %d\u{202F}s", minutes, seconds)
        } else {
            return String(format: "%d\u{202F}s", seconds)
        }
    }

    private func formatHoursComponent(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        return "\(hours)h"
    }

    private func formatMinutesComponent(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = (totalSeconds % 3600) / 60

        // For times less than an hour, just show minutes without "m" suffix
        if totalSeconds < 3600 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatSecondsComponent(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let seconds = totalSeconds % 60
        return "\(seconds)s"
    }
}

struct SettingsView: View {
    @EnvironmentObject private var timerModel: TimerModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    // Animation states
    @State private var selectedTab = 0
    @State private var slideOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom segmented control
                HStack(spacing: 0) {
                    ForEach(["Appearance", "Integration", "Alerts"], id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = ["Appearance", "Integration", "Alerts"].firstIndex(of: tab) ?? 0
                            }
                        }) {
                            Text(tab)
                                .font(.subheadline.weight(selectedTab == ["Appearance", "Integration", "Alerts"].firstIndex(of: tab) ? .semibold : .regular))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedTab == ["Appearance", "Integration", "Alerts"].firstIndex(of: tab) ? .primary : .secondary)
                        .background(
                            ZStack {
                                if selectedTab == ["Appearance", "Integration", "Alerts"].firstIndex(of: tab) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.1))
                                        .matchedGeometryEffect(id: "TAB", in: namespace)
                                }
                            }
                        )
                    }
                }
                .padding(4)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top)
                
                // Content for each tab
                TabView(selection: $selectedTab) {
                    // Appearance tab
                    Form {
                        // Background color picker
                        ColorPicker("Background Color", selection: $timerModel.backgroundColor)
                            .padding(.vertical, 4)
                        
                        // Background opacity control
                        HStack {
                            Text("Background Opacity")
                            Slider(value: $timerModel.backgroundOpacity, in: 0...1)
                                .transition(.opacity)
                        }
                        .padding(.vertical, 4)
                        
                        // Always on top toggle
                        Toggle("Keep Window Always on Top", isOn: $timerModel.windowAlwaysOnTop)
                            .padding(.vertical, 4)
                    }
                    .formStyle(.grouped)
                    .tag(0)
                    
                    // Integration tab
                    Form {
                        // Launch at login option
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .padding(.vertical, 4)
                        
                        // Show time in dock option
                        Toggle("Show Countdown in Dock", isOn: $timerModel.showInDock)
                            .padding(.vertical, 4)
                        
                        // Show time in menu bar option
                        Toggle("Show Countdown in Menu Bar", isOn: $timerModel.showInMenuBar)
                            .padding(.vertical, 4)
                    }
                    .formStyle(.grouped)
                    .tag(1)
                    
                    // Alerts tab
                    Form {
                        // Sound selection
                        Picker("Completion Sound", selection: $timerModel.selectedSound) {
                            Text("Default").tag("Default")
                            Text("Subtle").tag("Subtle")
                            Text("Loud").tag("Loud")
                            Text("Gentle").tag("Gentle")
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)
                    }
                    .formStyle(.grouped)
                    .tag(2)
                }
                .tabViewStyle(.automatic)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                
                // Done button
                Button("Done") {
                    withAnimation {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .frame(width: 400, height: 500)
    }
    
    @Namespace private var namespace
}

// Preview for development
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TimerModel())
            .preferredColorScheme(.dark)
    }
}
