import SwiftUI

struct HomeView: View {
    @State private var showingSettings = false
    
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
                        .padding()
                        
                        Spacer()
                    }
                    .padding()
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
        }
    }
}

#Preview {
    HomeView()
}