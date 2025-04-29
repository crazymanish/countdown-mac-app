import SwiftUI
import AppKit

// Window level preference key to pass the level through the view hierarchy
struct WindowLevelKey: PreferenceKey {
    static var defaultValue: NSWindow.Level = .normal
    
    static func reduce(value: inout NSWindow.Level, nextValue: () -> NSWindow.Level) {
        value = nextValue()
    }
}

// Window finder that attaches to SwiftUI view hierarchy
struct WindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            callback(nsView.window)
        }
    }
}

// Window level modifier
struct WindowLevelModifier: ViewModifier {
    @Binding var alwaysOnTop: Bool
    
    func body(content: Content) -> some View {
        content
            .preference(key: WindowLevelKey.self, value: alwaysOnTop ? .floating : .normal)
            .onPreferenceChange(WindowLevelKey.self) { level in
                DispatchQueue.main.async {
                    NSApplication.shared.windows.forEach { window in
                        window.level = level
                    }
                }
            }
            .background(
                WindowFinder { window in
                    window?.level = self.alwaysOnTop ? .floating : .normal
                    window?.collectionBehavior = self.alwaysOnTop ? 
                        [.canJoinAllSpaces, .fullScreenAuxiliary] : []
                }
            )
    }
}

// Extension to make it easier to use
extension View {
    func windowLevel(alwaysOnTop: Binding<Bool>) -> some View {
        self.modifier(WindowLevelModifier(alwaysOnTop: alwaysOnTop))
    }
}