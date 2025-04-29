import SwiftUI
import AVFoundation
import UserNotifications
import AppKit
import Observation

@Observable
@MainActor
class TimerModel {
    var timeRemaining: TimeInterval = 0
    var targetDuration: TimeInterval = 0
    var isRunning = false
    var inputText = ""
    var statusMessage = ""
    var completionMessage = ""
    var selectedSound: String = "Default"
    var inputHistory: [String] = []
    var historyIndex: Int = -1
    var shouldFocusInput: Bool = true
    
    private var timerTask: Task<Void, Never>?
    private var isPaused = true // Track if timer is paused
    private var audioPlayer: AVAudioPlayer?
    private var soundOptions = ["Default", "Subtle", "Loud", "Gentle"]
    
    // For window customization
    var backgroundColor: Color = .clear
    var backgroundOpacity: Double = 0.9
    var windowAlwaysOnTop: Bool = true
    
    init() {
        // Initialize with default values
        loadSoundOptions()
        // Initialize the timer task that will live throughout the app's lifecycle
        createTimerTask()
    }
    
    private func loadSoundOptions() {
        // Get available sounds from SoundManager
        Task {
            soundOptions = await SoundManager.shared.getAllSoundNames()
        }
    }
    
    private func createTimerTask() {
        // Only create a new task if one doesn't exist
        guard timerTask == nil else { return }
        
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                if isRunning && timeRemaining > 0 {
                    // Timer is running, update time
                    if self.timeRemaining > 0.1 {
                        self.timeRemaining -= 0.1
                    } else {
                        self.timerCompleted()
                    }
                    // Sleep for 0.1 seconds
                    try? await Task.sleep(for: .milliseconds(100))
                } else {
                    // Timer is paused, sleep briefly to avoid high CPU usage
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        }
    }
    
    func startTimer() {
        guard timeRemaining > 0 else {
            resetTimer()
            return
        }
        
        isRunning = true
        shouldFocusInput = false // Turn off focus when timer starts
        
        // Ensure timer task exists
        createTimerTask()
    }
    
    func pauseTimer() {
        isRunning = false
        // We don't cancel the task, just update the isRunning flag
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
        completionMessage = "Countdown completed!"
        shouldFocusInput = true // Return focus to input field when timer completes
        
        // Play bell sound alert
        Task {
            await SoundManager.shared.play(sound: "Bell")
        }
        
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
        Task {
            await SoundManager.shared.play(sound: selectedSound)
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Countdown Timer"
        content.body = "Your countdown has finished!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
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
