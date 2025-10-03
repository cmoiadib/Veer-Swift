import SwiftUI

struct ProfileView: View {
    @Environment(\.clerkManager) private var clerkManager
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Button(action: {
                            // Profile image action
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.regularMaterial)
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                                
                                // Edit overlay
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.primary)
                                    }
                                    .offset(x: 35, y: 35)
                            }
                        }
                        
                        // User Info
                        VStack(spacing: 8) {
                            if let user = clerkManager.user {
                                Text(user.fullName.isEmpty ? "User" : user.fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text(user.email)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("John Doe")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text("john.doe@example.com")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Member since January 2024")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        // Edit Profile Button
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("Edit Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Photos",
                                value: "24",
                                systemImage: "photo.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Followers",
                                value: "156",
                                systemImage: "person.2.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Following",
                                value: "89",
                                systemImage: "heart.fill",
                                color: .red
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Menu Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 0) {
                            MenuRow(
                                title: "Settings",
                                subtitle: "Preferences and privacy",
                                systemImage: "gearshape.fill",
                                action: {
                                    showingSettings = true
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            MenuRow(
                                title: "Notifications",
                                subtitle: "Manage notifications",
                                systemImage: "bell.fill",
                                action: {
                                    // Notifications action
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            MenuRow(
                                title: "Privacy",
                                subtitle: "Data and security",
                                systemImage: "lock.fill",
                                action: {
                                    // Privacy action
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            MenuRow(
                                title: "Help & Support",
                                subtitle: "Get help and contact us",
                                systemImage: "questionmark.circle.fill",
                                action: {
                                    // Help action
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Sign Out Button
                    Button(action: {
                        clerkManager.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MenuRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.blue)
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = "John Doe"
    @State private var email = "john.doe@example.com"
    @State private var bio = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save changes
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}