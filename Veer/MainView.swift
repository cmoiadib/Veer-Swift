import SwiftUI

struct MainView: View {
    @Environment(\.clerkManager) private var clerkManager
    
    var body: some View {
        MainTabView()
            .environment(\.clerkManager, clerkManager)
    }
}

#Preview {
    MainView()
        .environment(\.clerkManager, ClerkManager(publishableKey: "test"))
}