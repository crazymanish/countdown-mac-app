import SwiftUI

struct StatusView: View {
    @Environment(TimerModel.self) private var timerModel
    
    var body: some View {
        if (!timerModel.completionMessage.isEmpty) {
            Text(timerModel.completionMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LinearGradient.appGradient)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.1))
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
}

#Preview {
    StatusView()
        .environment(TimerModel())
}