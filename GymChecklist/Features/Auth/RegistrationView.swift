import SwiftUI

@MainActor
struct RegistrationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSignIn = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("authEmail")
                    SecureField("Password", text: $password)
                        .textContentType(isSignIn ? .password : .newPassword)
                        .accessibilityIdentifier("authPassword")
                    if !isSignIn {
                        SecureField("Confirm password", text: $confirmation)
                            .textContentType(.newPassword)
                            .accessibilityIdentifier("authConfirmPassword")
                    }
                } header: {
                    Text(isSignIn ? "Sign in" : "Create your account")
                } footer: {
                    Text(isSignIn ? "" : "Use at least 6 characters for your password.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("authRegistrationError")
                    }
                }

                Section {
                    Button(buttonTitle) {
                        Task {
                            if isSignIn {
                                _ = await viewModel.signIn(email: email, password: password)
                            } else {
                                _ = await viewModel.register(email: email, password: password, confirmation: confirmation)
                            }
                            password = ""
                            confirmation = ""
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier(isSignIn ? "authSignIn" : "authRegister")

                    Button(isSignIn ? "Create an account" : "Already have an account? Sign in") {
                        isSignIn.toggle()
                        password = ""
                        confirmation = ""
                        viewModel.clearError()
                    }
                    .accessibilityIdentifier(isSignIn ? "authShowRegistration" : "authShowSignIn")
                }
            }
            .navigationTitle("Gym Checklist")
            .accessibilityIdentifier(isSignIn ? "authSignInScreen" : "authRegistrationScreen")
        }
        .onDisappear {
            password = ""
            confirmation = ""
        }
    }

    private var buttonTitle: String {
        if viewModel.isSubmitting { return isSignIn ? "Signing in…" : "Creating account…" }
        return isSignIn ? "Sign in" : "Create account"
    }
}
