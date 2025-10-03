import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to Veer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Discover amazing features and connect with others")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Quick Actions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        QuickActionCard(
                            title: "Camera",
                            subtitle: "Capture moments",
                            systemImage: "camera.fill",
                            color: .blue
                        )
                        
                        QuickActionCard(
                            title: "Profile",
                            subtitle: "Manage account",
                            systemImage: "person.circle.fill",
                            color: .green
                        )
                        
                        QuickActionCard(
                            title: "Settings",
                            subtitle: "Preferences",
                            systemImage: "gearshape.fill",
                            color: .orange
                        )
                        
                        QuickActionCard(
                            title: "Help",
                            subtitle: "Get support",
                            systemImage: "questionmark.circle.fill",
                            color: .purple
                        )
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 8) {
                            ActivityRow(
                                title: "Photo uploaded",
                                subtitle: "2 minutes ago",
                                systemImage: "photo.fill"
                            )
                            
                            ActivityRow(
                                title: "Profile updated",
                                subtitle: "1 hour ago",
                                systemImage: "person.fill"
                            )
                            
                            ActivityRow(
                                title: "Settings changed",
                                subtitle: "Yesterday",
                                systemImage: "gearshape.fill"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}