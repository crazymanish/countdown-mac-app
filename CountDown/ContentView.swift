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
            
            VStack(spacing: 8) {
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
            Text(formatTimeDisplay(timerModel.timeRemaining))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 1.0), value: timerModel.timeRemaining)
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
        HStack(spacing: 8) {
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
        HStack(spacing: 8) {
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

    // Helper function for time formatting
    private func formatTimeDisplay(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d h %02d m %02d s", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%02d m %02d s", minutes, seconds)
        } else {
            return String(format: "%02d s", seconds)
        }
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
