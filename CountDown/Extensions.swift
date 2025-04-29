import SwiftUI

extension LinearGradient {
    static var appGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.pink, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}