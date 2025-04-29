import SwiftUI
import AVFoundation
import UserNotifications
import AppKit

class TimerModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var targetDuration: TimeInterval = 0
    @Published var isRunning = false
    @Published var inputText = ""
    @Published var statusMessage = ""
    @Published var completionMessage = ""
    @Published var selectedSound: String = "Default"
    @Published var inputHistory: [String] = []
    @Published var historyIndex: Int = -1
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var soundOptions = ["Default", "Subtle", "Loud", "Gentle"]
    
    // For window customization
    @Published var backgroundColor: Color = .clear
    @Published var backgroundOpacity: Double = 0.9
    @Published var windowAlwaysOnTop: Bool = true
    
    // For system integration
    @Published var showInDock: Bool = true
    @Published var showInMenuBar: Bool = true
    
    private var statusItem: NSStatusItem?
    
    init() {
        // Initialize with default values
        loadSoundOptions()
        
        // Set up menu bar item if enabled
        if showInMenuBar {
            setupMenuBarItem()
        }
    }
    
    private func loadSoundOptions() {
        // Get available sounds from SoundManager
        soundOptions = SoundManager.shared.getAllSoundNames()
    }
    
    func startTimer() {
        guard timeRemaining > 0 else {
            resetTimer()
            return
        }
        
        isRunning = true
        
        // Invalidate any existing timer
        timer?.invalidate()
        
        // Create a new timer that fires every 0.1 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0.1 {
                self.timeRemaining -= 0.1
                self.updateDockAndMenuBar()
            } else {
                self.timerCompleted()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = targetDuration
        completionMessage = ""
    }
    
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func timerCompleted() {
        timeRemaining = 0
        isRunning = false
        timer?.invalidate()
        completionMessage = "Countdown completed!"
        
        // Play bell sound alert
        SoundManager.shared.play(sound: "Bell")
        
        // Display system notification
        sendNotification()
    }
    
    func parseInput() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip empty input
        guard !input.isEmpty else { return }
        
        // Check if this is a relative adjustment
        if let duration = parseNaturalLanguageInput(input) {
            targetDuration = duration
            timeRemaining = duration
            statusMessage = "Timer set for \(formattedTime(duration))"
            
            // Add to history if not already the most recent entry
            if inputHistory.isEmpty || inputHistory.last != input {
                inputHistory.append(input)
                // Limit history to last 20 entries
                if inputHistory.count > 20 {
                    inputHistory.removeFirst()
                }
            }
            historyIndex = inputHistory.count
            
            inputText = ""
            
            // Auto-start the timer after input is parsed
            startTimer()
        } else {
            statusMessage = "Could not understand input. Try something like '1 hour 30 minutes'"
        }
    }
    
    func parseNaturalLanguageInput(_ input: String) -> TimeInterval? {
        // This will be expanded with a more sophisticated parser
        // For now, implementing a basic parser for demonstration
        
        let lowercaseInput = input.lowercased()
        
        // Check for relative adjustments (add/subtract)
        if lowercaseInput.contains("add") {
            if let timeString = lowercaseInput.components(separatedBy: "add ").last,
               let time = parseTimeComponents(timeString) {
                return timeRemaining + time
            }
            return nil
        } else if lowercaseInput.contains("subtract") || lowercaseInput.contains("sub") {
            if let timeString = lowercaseInput.components(separatedBy: lowercaseInput.contains("subtract") ? "subtract " : "sub ").last,
               let time = parseTimeComponents(timeString) {
                return max(0, timeRemaining - time)
            }
            return nil
        } else {
            // Regular time input
            return parseTimeComponents(lowercaseInput)
        }
    }
    
    private func parseTimeComponents(_ input: String) -> TimeInterval? {
        let input = input.lowercased()
        var totalSeconds: TimeInterval = 0
        
        // Handle different units and formats
        
        // Days
        if let days = extractNumber(for: "day", in: input) {
            totalSeconds += days * 86400
        }
        
        // Hours
        if let hours = extractNumber(for: "hour", in: input) {
            totalSeconds += hours * 3600
        } else if let hours = extractNumber(for: "h", in: input) {
            totalSeconds += hours * 3600
        }
        
        // Minutes
        if let minutes = extractNumber(for: "minute", in: input) {
            totalSeconds += minutes * 60
        } else if let minutes = extractNumber(for: "min", in: input) {
            totalSeconds += minutes * 60
        } else if let minutes = extractNumber(for: "m", in: input) {
            totalSeconds += minutes * 60
        }
        
        // Seconds
        if let seconds = extractNumber(for: "second", in: input) {
            totalSeconds += seconds
        } else if let seconds = extractNumber(for: "sec", in: input) {
            totalSeconds += seconds
        } else if let seconds = extractNumber(for: "s", in: input) {
            totalSeconds += seconds
        }
        
        // If no unit identifier found, try to parse as just minutes
        if totalSeconds == 0 {
            if let plainNumber = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) {
                totalSeconds = plainNumber * 60  // Default unit is minutes
            }
        }
        
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    private func extractNumber(for unit: String, in input: String) -> Double? {
        // This will extract numbers associated with time units
        // For example, from "1 hour and 30 minutes", it will extract 1 for "hour" and 30 for "minute"
        
        let pattern = "(\\d+(?:\\.\\d+)?)\\s*\(unit)s?"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        if let match = regex?.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count)) {
            if let numberRange = Range(match.range(at: 1), in: input) {
                return Double(input[numberRange])
            }
        }
        
        return nil
    }
    
    func previousHistoryItem() {
        guard !inputHistory.isEmpty && historyIndex > 0 else { return }
        historyIndex -= 1
        inputText = inputHistory[historyIndex]
    }
    
    func nextHistoryItem() {
        guard !inputHistory.isEmpty else { return }
        
        if historyIndex < inputHistory.count - 1 {
            historyIndex += 1
            inputText = inputHistory[historyIndex]
        } else if historyIndex == inputHistory.count - 1 {
            // At the end of history, clear the input
            historyIndex = inputHistory.count
            inputText = ""
        }
    }
    
    func playCompletionSound() {
        // Use the SoundManager to play the selected sound
        SoundManager.shared.play(sound: selectedSound)
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Countdown Timer"
        content.body = "Your countdown has finished!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func updateDockAndMenuBar() {
        // Update dock icon badge if enabled
        if showInDock {
            updateDockIcon()
        }
        
        // Update menu bar item if enabled
        if showInMenuBar {
            updateMenuBarItem()
        }
    }
    
    private func updateDockIcon() {
        DispatchQueue.main.async {
            if self.timeRemaining > 0 {
                NSApplication.shared.dockTile.badgeLabel = self.formattedTime(self.timeRemaining)
            } else {
                NSApplication.shared.dockTile.badgeLabel = nil
            }
        }
    }
    
    private func setupMenuBarItem() {
        DispatchQueue.main.async {
            self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            self.statusItem?.button?.title = "--:--"
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Start/Pause", action: #selector(NSApplication.shared.sendAction(_:to:from:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Reset", action: #selector(NSApplication.shared.sendAction(_:to:from:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q"))
            
            self.statusItem?.menu = menu
            
            // Set initial value
            self.updateMenuBarItem()
        }
    }
    
    private func updateMenuBarItem() {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button {
                if self.timeRemaining > 0 {
                    button.title = self.formattedTime(self.timeRemaining)
                } else {
                    button.title = "--:--"
                }
            }
        }
    }
    
    func removeMenuBarItem() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days)d")
        }
        
        if hours > 0 {
            components.append("\(hours)h")
        }
        
        if minutes > 0 {
            components.append("\(minutes)m")
        }
        
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds)s")
        }
        
        return components.joined(separator: " ")
    }
}
