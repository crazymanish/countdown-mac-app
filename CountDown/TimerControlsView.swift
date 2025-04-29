import SwiftUI
import AppKit

struct TimerControlsView: View {
    @Environment(TimerModel.self) private var timerModel
    @State private var rotationDegrees: Double = 0
    @Binding var isPresentingSettings: Bool
    
    var body: some View {
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
}

#Preview {
    TimerControlsView(isPresentingSettings: .constant(false))
        .environment(TimerModel())
}