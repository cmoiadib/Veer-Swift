import SwiftUI

struct WelcomeView: View {
    @State private var showingAuth = false

    var body: some View {
        ZStack {
            // Gradient Background - matches the image
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.75, blue: 0.95),  // Light pink top
                    Color(red: 0.98, green: 0.4, blue: 0.8),   // Hot pink
                    Color(red: 0.85, green: 0.3, blue: 0.9),   // Magenta
                    Color(red: 0.6, green: 0.3, blue: 0.95),   // Purple
                    Color(red: 0.4, green: 0.35, blue: 0.85)   // Deep purple bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Title and Subtitle
                VStack(spacing: 16) {
                    Text("Veer")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("AI-Powered Virtual Try-On")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 60)

                Spacer()

                // Get Started Button
                Button {
                    showingAuth = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .sensoryFeedback(.selection, trigger: showingAuth)
            }
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationSheet()
        }
    }
}

// MARK: - Authentication Sheet
struct AuthenticationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerkManager) private var clerkManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Welcome")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Sign in to continue")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)

                        // Email/Password Form
                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 24)

                        Button(action: {
                            handleSignIn()
                        }) {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        Button {
                            dismiss()
                        } label: {
                            Text("Skip for now")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func handleSignIn() {
        isLoading = true

        Task {
            await clerkManager.signIn(email: email, password: password)

            await MainActor.run {
                isLoading = false
                if clerkManager.errorMessage != nil {
                    errorMessage = clerkManager.errorMessage ?? "Sign in failed. Please try again."
                    showingError = true
                } else {
                    Task {
                        await dismissWithAnimation()
                    }
                }
            }
        }
    }

    private func dismissWithAnimation() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAuthenticating = true
            }
        }

        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        await MainActor.run {
            dismiss()
        }
    }
}

#Preview {
    WelcomeView()
}
