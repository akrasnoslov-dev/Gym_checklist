import AuthenticationServices
import SwiftUI

@MainActor
struct RegistrationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSignIn = false
    @State private var isResettingPassword = false
    @State private var appleSignInNonce: String?
    @AccessibilityFocusState private var isErrorFocused: Bool

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
                    if !isResettingPassword { SecureField("Password", text: $password)
                        .textContentType(isSignIn ? .password : .newPassword)
                        .accessibilityIdentifier("authPassword")
                    }
                    if !isSignIn && !isResettingPassword {
                        SecureField("Confirm password", text: $confirmation)
                            .textContentType(.newPassword)
                            .accessibilityIdentifier("authConfirmPassword")
                    }
                } header: {
                    Text(isResettingPassword ? "Reset password" : (isSignIn ? "Sign in" : "Create your account"))
                } footer: {
                    Text(isSignIn ? "" : "Use at least 6 characters for your password.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($isErrorFocused)
                            .accessibilityIdentifier("authRegistrationError")
                    }
                }
                if let message = viewModel.passwordResetMessage { Section { Text(message).accessibilityIdentifier("authResetMessage") } }

                Section {
                    Button(buttonTitle) {
                        Task {
                            if isResettingPassword {
                                _ = await viewModel.sendPasswordReset(email: email)
                            } else if isSignIn {
                                _ = await viewModel.signIn(email: email, password: password)
                            } else {
                                _ = await viewModel.register(email: email, password: password, confirmation: confirmation)
                            }
                            password = ""
                            confirmation = ""
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier(isResettingPassword ? "authSendReset" : (isSignIn ? "authSignIn" : "authRegister"))

                    if !isResettingPassword {
#if DEBUG
                        if FirebaseBootstrap.isRunningTests() {
                            Button("Continue with Apple") {
                                Task {
                                    _ = await viewModel.signInWithApple(
                                        identityToken: "ui-test-token",
                                        rawNonce: "ui-test-nonce"
                                    )
                                }
                            }
                            .disabled(viewModel.isSubmitting)
                            .accessibilityIdentifier("authSignInWithApple")
                        } else {
                            appleSignInButton
                        }
#else
                        appleSignInButton
#endif
                    }

                    if isSignIn && !isResettingPassword { Button("Forgot password?") { isResettingPassword = true; viewModel.clearFeedback() }.accessibilityIdentifier("authForgotPassword") }
                    Button(isResettingPassword ? "Back to sign in" : (isSignIn ? "Create an account" : "Already have an account? Sign in")) {
                        if isResettingPassword { isResettingPassword = false; isSignIn = true } else {
                        isSignIn.toggle()
                        }
                        password = ""
                        confirmation = ""
                        viewModel.clearFeedback()
                    }
                    .accessibilityIdentifier(isResettingPassword ? "authBackToSignIn" : (isSignIn ? "authShowRegistration" : "authShowSignIn"))
                }
            }
            .navigationTitle("Gym Checklist")
            .accessibilityIdentifier(isResettingPassword ? "authPasswordResetScreen" : (isSignIn ? "authSignInScreen" : "authRegistrationScreen"))
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if newValue != nil { isErrorFocused = true }
            }
        }
        .onDisappear {
            password = ""
            confirmation = ""
        }
    }

    private var buttonTitle: String {
        if viewModel.isSubmitting { return isResettingPassword ? "Sending…" : (isSignIn ? "Signing in…" : "Creating account…") }
        if isResettingPassword { return "Send reset instructions" }
        return isSignIn ? "Sign in" : "Create account"
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            appleSignInNonce = AppleSignInRequest.configure(request)
        } onCompletion: { result in
            Task {
                switch result {
                case .success(let authorization):
                    guard let nonce = appleSignInNonce,
                          let token = AppleSignInRequest.identityToken(from: authorization) else {
                        viewModel.handleAppleSignInFailure(RegistrationError.unavailable)
                        return
                    }
                    _ = await viewModel.signInWithApple(identityToken: token, rawNonce: nonce)
                case .failure(let error):
                    viewModel.handleAppleSignInFailure(error)
                }
                appleSignInNonce = nil
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(minHeight: 44)
        .disabled(viewModel.isSubmitting)
        .accessibilityIdentifier("authSignInWithApple")
    }
}
