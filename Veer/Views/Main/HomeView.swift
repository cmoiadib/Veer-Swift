import SwiftUI

struct HomeView: View {
    @State private var showingSettings = false
    @Environment(\.supabaseManager) private var supabaseManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Glass-like translucent background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Back Section
                        VStack(spacing: 12) {
                            Text("Welcome Back")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                        // Token Summary Card
                        if !supabaseManager.tokens.isEmpty {
                            TokenSummaryCard(
                                totalValue: supabaseManager.tokens.reduce(0) { $0 + $1.tokenValue },
                                tokenCount: supabaseManager.tokens.count
                            )
                            .padding(.horizontal)
                        }
                        
                        // Loading, Error, or Content States
                        if supabaseManager.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading your tokens...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let errorMessage = supabaseManager.errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundStyle(.orange)
                                
                                Text("Unable to load tokens")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") {
                                    loadTokens()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else if supabaseManager.tokens.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.yellow)
                                
                                Text("No Tokens Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Start taking photos and creating outfits to earn your first tokens!")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            // Group tokens by type
                            let groupedTokens = Dictionary(grouping: supabaseManager.tokens) { $0.tokenType }
                            
                            LazyVStack(spacing: 20) {
                                // Style tokens
                                if let styleTokens = groupedTokens["style"], !styleTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Style Points",
                                        tokens: styleTokens,
                                        color: .purple,
                                        icon: "sparkles"
                                    )
                                    .padding(.horizontal)
                                }
                                
                                // Photo tokens
                                if let photoTokens = groupedTokens["photo"], !photoTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Photo Rewards",
                                        tokens: photoTokens,
                                        color: .blue,
                                        icon: "camera.fill"
                                    )
                                    .padding(.horizontal)
                                }
                                
                                // Achievement tokens
                                if let achievementTokens = groupedTokens["achievement"], !achievementTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Achievements",
                                        tokens: achievementTokens,
                                        color: .green,
                                        icon: "trophy.fill"
                                    )
                                    .padding(.horizontal)
                                }
                                
                                // Other token types
                                ForEach(Array(groupedTokens.keys.sorted()), id: \.self) { type in
                                    if !["style", "photo", "achievement"].contains(type) {
                                        TokenTypeSection(
                                            title: type.capitalized,
                                            tokens: groupedTokens[type] ?? [],
                                            color: .orange,
                                            icon: "star.fill"
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    loadTokens()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                loadTokens()
            }
        }
    }
    
    private func loadTokens() {
        Task {
            await supabaseManager.fetchTokens(for: "sample-user-id")
        }
    }
}

#Preview {
    HomeView()
}