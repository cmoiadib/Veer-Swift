import SwiftUI

struct WelcomeView: View {
    @Environment(\.clerkManager) private var clerkManager
    @State private var isShowingLogin = false
    @State private var isShowingRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with system blur
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // App Logo/Icon
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)
                            .symbolEffect(.pulse)

                        Text("Welcome to Veer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Connect and discover amazing experiences")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Authentication Buttons
                    VStack(spacing: 16) {
                        // Login Button
                        Button(action: {
                            isShowingLogin = true
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Sign in to your account")

                        // Register Button
                        Button(action: {
                            isShowingRegister = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.glassProminent)
                        .accessibilityLabel("Create a new account")

                        // Terms and Privacy
                        VStack(spacing: 8) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // Handle terms action
                                }
                                .foregroundStyle(.blue)

                                Text("and")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Button("Privacy Policy") {
                                    // Handle privacy action
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $isShowingLogin) {
            NavigationStack {
                LoginView()
                    .navigationTitle("Sign In")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingLogin = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $isShowingRegister) {
            NavigationStack {
                RegisterView()
                    .navigationTitle("Create Account")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingRegister = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
    }
}

// Placeholder Login View
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerkManager) private var clerkManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: {
                    Task {
                        await signIn()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = ""

        do {
            await clerkManager.signIn(email: email, password: password)
            if clerkManager.isAuthenticated {
                dismiss()
            } else if let error = clerkManager.errorMessage {
                errorMessage = error
            }
        } catch {
            errorMessage = "Sign in failed. Please try again."
        }

        isLoading = false
    }
}

// Placeholder Register View
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerkManager) private var clerkManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                if password != confirmPassword && !confirmPassword.isEmpty {
                    Text("Passwords do not match")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: {
                    Task {
                        await signUp()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword || isLoading)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    private func signUp() async {
        isLoading = true
        errorMessage = ""

        do {
            await clerkManager.signUp(email: email, password: password)
            if clerkManager.isAuthenticated {
                dismiss()
            } else if let error = clerkManager.errorMessage {
                errorMessage = error
            }
        } catch {
            errorMessage = "Registration failed. Please try again."
        }

        isLoading = false
    }
}

#Preview {
    WelcomeView()
}
