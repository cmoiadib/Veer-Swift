import SwiftUI
import Foundation
import Combine
import Clerk

// MARK: - Clerk Manager
@MainActor
class ClerkManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: ClerkUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Clerk configuration
    private let publishableKey: String

    init(publishableKey: String) {
        self.publishableKey = publishableKey
        checkAuthenticationStatus()
    }

    // MARK: - Authentication Methods

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use real Clerk iOS SDK for authentication
            let signIn = try await SignIn.create(
                strategy: .identifier(email, password: password)
            )

            if signIn.status == .complete {
                // Authentication successful - update our local state
                await updateAuthenticationState()
            } else {
                self.errorMessage = "Authentication failed. Please check your credentials."
            }

        } catch {
            self.errorMessage = "Authentication failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use real Clerk iOS SDK for sign up
            let signUp = try await SignUp.create(
                strategy: .standard(emailAddress: email, password: password)
            )

            if signUp.status == .complete {
                // Sign up successful - update our local state
                await updateAuthenticationState()
            } else {
                self.errorMessage = "Sign up failed. Please try again."
            }

        } catch {
            self.errorMessage = "Sign up failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signOut() {
        Task {
            do {
                try await Clerk.shared.signOut()
                await MainActor.run {
                    self.isAuthenticated = false
                    self.user = nil
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Sign out failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateAuthenticationState() async {
        // Update authentication state based on Clerk's current user
        if let clerkUser = Clerk.shared.user {
            let user = ClerkUser(
                id: clerkUser.id,
                email: clerkUser.primaryEmailAddress?.emailAddress ?? "",
                firstName: clerkUser.firstName,
                lastName: clerkUser.lastName
            )

            self.user = user
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
            self.user = nil
        }
    }

    private func checkAuthenticationStatus() {
        // Check if user is already authenticated with Clerk
        Task {
            await updateAuthenticationState()
        }
    }

    // Public method to refresh authentication state
    func refreshAuthenticationState() async {
        await updateAuthenticationState()
    }
}

// MARK: - Clerk User Model
struct ClerkUser: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?

    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Clerk API Response Models
struct ClerkSignInResponse: Codable {
    let response: ClerkSignInData?
}

struct ClerkSignInData: Codable {
    let user: ClerkAPIUser?
}

struct ClerkAPIUser: Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    let emailAddresses: [ClerkEmailAddress]?
}

struct ClerkEmailAddress: Codable {
    let emailAddress: String
}

// MARK: - Environment Key
private struct ClerkManagerKey: EnvironmentKey {
    static let defaultValue = ClerkManager(publishableKey: "")
}

extension EnvironmentValues {
    var clerkManager: ClerkManager {
        get { self[ClerkManagerKey.self] }
        set { self[ClerkManagerKey.self] = newValue }
    }
}
