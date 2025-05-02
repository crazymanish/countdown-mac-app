# CountDown

A sleek, floating countdown timer app for macOS that stays on top of other windows, helping you manage your time efficiently.

## Features

- **Floating Timer Window**: Always stays on top of other applications (can be toggled)
- **Natural Language Input**: Easily set timers using natural language (e.g., "1 hour 30 minutes", "10m", "2h 15m")
- **Sound Notifications**: Get alerted when your timer completes
- **Keyboard Shortcuts**: Control the timer without disrupting your workflow
- **Customizable Appearance**: Choose background color and opacity to suit your preferences
- **Command History**: Quickly access and reuse previous timer inputs
- **System Notifications**: Receive macOS notifications when timers complete

## Demo

<img width="200" alt="Screenshot 2025-04-29 at 11 09 25" src="https://github.com/user-attachments/assets/a147f217-0617-4b0e-83aa-473a0013e998" />

## Requirements

- macOS 15.3 or later
- Xcode 16.3 or later (for building from source)

## Installation

### Option 1: Download the release
1. Go to the [Releases](https://github.com/manishrathi/countdown-mac-app/releases) page
2. Download the latest version
3. Move the app to your Applications folder

### Option 2: Build from source
1. Clone the repository:
   ```bash
   git clone https://github.com/manishrathi/countdown-mac-app.git
   cd countdown-mac-app
   ```
2. Open the Xcode project:
   ```bash
   open CountDown.xcodeproj
   ```
3. Build and run the app in Xcode (⌘+R)

## Usage

### Setting a timer
1. Type a duration in the input field (e.g., "1h 30m", "45s", "2 hours")
2. Press Enter or click the arrow button

### Timer controls
- **Play/Pause**: Space bar or click the play/pause button
- **Reset**: ⌘+R or click the reset button
- **Settings**: Click the gear icon

### Keyboard Shortcuts
- **Start/Pause Timer**: Space
- **Reset Timer**: ⌘+R
- **Open Settings**: ⌘+,
- **Navigate Timer History**: Up/Down arrows

### Advanced Input
- Simple inputs: "10" (defaults to minutes)
- Detailed inputs: "1h 30m 45s" (hours, minutes, seconds)
- Abbreviated inputs: "1h", "30m", "45s"

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Manish Rathi
