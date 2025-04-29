import SwiftUI
import UserNotifications
import Observation

struct TimerInputView: View {
    @Environment(TimerModel.self) private var timerModel
    @FocusState private var isInputFieldFocused: Bool
    
    var body: some View {
        @Bindable var timerModel = timerModel

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
                .onChange(of: timerModel.shouldFocusInput) { oldValue, newValue in
                    // Sync FocusState with the TimerModel's shouldFocusInput property
                    isInputFieldFocused = newValue
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
}

#Preview {
    TimerInputView()
        .environment(TimerModel())
}
