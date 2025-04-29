import SwiftUI

struct TimerView: View {
    @Environment(TimerModel.self) private var timerModel
    @State private var isTimerPulsing = false
    
    var body: some View {
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
        .padding(.bottom, 4)
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

#Preview {
    TimerView()
        .environment(TimerModel())
}
