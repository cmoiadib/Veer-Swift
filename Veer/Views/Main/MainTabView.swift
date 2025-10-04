import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Environment(\.clerkManager) private var clerkManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
                .onChange(of: selectedTab) { oldValue, newValue in
                    // Refresh when switching to Home tab
                    if newValue == 0, let userId = clerkManager.user?.id {
                        Task {
                            await supabaseManager.fetchOutfits(for: userId)
                        }
                    }
                }

            CameraView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "wand.and.stars" : "wand.and.stars")
                    Text("Try-On")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(.blue)
        .onAppear {
            // Configure tab bar appearance for liquid glass effect
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()

            // Use system materials for liquid glass effect
            appearance.backgroundColor = UIColor.clear

            // Configure tab bar item appearance
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]

            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]

            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
