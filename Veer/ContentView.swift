import SwiftUI

struct ContentView: View {
    @Environment(\.clerkManager) private var clerkManager

    var body: some View {
        Group {
            if clerkManager.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: clerkManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
