import SwiftUI
import UserNotifications
import AppKit

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
