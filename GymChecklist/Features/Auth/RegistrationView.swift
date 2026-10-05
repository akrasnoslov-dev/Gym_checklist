import AuthenticationServices
import GoogleSignInSwift
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
            ScrollView {
                VStack(spacing: GymTheme.spacing20) {
                    Spacer(minLength: 54)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(GymTheme.accentFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(spacing: GymTheme.spacing8) {
                        Text(authTitle)
                            .font(.title.weight(.bold))
                            .foregroundStyle(GymTheme.textPrimary)
                        Text(authSubtitle)
                            .font(.body)
                            .foregroundStyle(GymTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: GymTheme.spacing4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(GymTheme.textSecondary)
                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .accessibilityIdentifier("authEmail")
                        }
                        .padding(.horizontal, GymTheme.spacing16)
                        .padding(.vertical, GymTheme.spacing12)

                        if !isResettingPassword {
                            Divider().overlay(GymTheme.separator)
                            VStack(alignment: .leading, spacing: GymTheme.spacing4) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundStyle(GymTheme.textSecondary)
                                SecureField("Password", text: $password)
                                    .textContentType(isSignIn ? .password : .newPassword)
                                    .accessibilityIdentifier("authPassword")
                            }
                            .padding(.horizontal, GymTheme.spacing16)
                            .padding(.vertical, GymTheme.spacing12)
                        }

                        if !isSignIn && !isResettingPassword {
                            Divider().overlay(GymTheme.separator)
                            VStack(alignment: .leading, spacing: GymTheme.spacing4) {
                                Text("Confirm password")
                                    .font(.caption)
                                    .foregroundStyle(GymTheme.textSecondary)
                                SecureField("Confirm password", text: $confirmation)
                                    .textContentType(.newPassword)
                                    .accessibilityIdentifier("authConfirmPassword")
                            }
                            .padding(.horizontal, GymTheme.spacing16)
                            .padding(.vertical, GymTheme.spacing12)
                        }
                    }
                    .background(
                        GymTheme.surfaceGrouped,
                        in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                            .stroke(GymTheme.borderSubtle, lineWidth: 1)
                    }

                    if !isSignIn && !isResettingPassword {
                        Text("Use at least 6 characters for your password.")
                            .font(.footnote)
                            .foregroundStyle(GymTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(GymTheme.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($isErrorFocused)
                            .accessibilityIdentifier("authRegistrationError")
                    }

                    if let message = viewModel.passwordResetMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(GymTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("authResetMessage")
                    }

                    Button(buttonTitle, action: submit)
                        .buttonStyle(GymPrimaryButtonStyle())
                        .disabled(viewModel.isSubmitting)
                        .opacity(viewModel.isSubmitting ? 0.6 : 1)
                        .accessibilityIdentifier(isResettingPassword ? "authSendReset" : (isSignIn ? "authSignIn" : "authRegister"))

                    if isSignIn && !isResettingPassword {
                        Button("Forgot password?") {
                            isResettingPassword = true
                            viewModel.clearFeedback()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(GymTheme.accentForeground)
                        .accessibilityIdentifier("authForgotPassword")
                    }

                    if !isResettingPassword {
                        HStack(spacing: GymTheme.spacing12) {
                            Rectangle().fill(GymTheme.separator).frame(height: 1)
                            Text("or")
                                .font(.footnote)
                                .foregroundStyle(GymTheme.textSecondary)
                            Rectangle().fill(GymTheme.separator).frame(height: 1)
                        }

                        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
                            Button("Continue with Google") {
                                Task { _ = await viewModel.signInWithGoogle() }
                            }
                            .buttonStyle(GymSecondaryButtonStyle())
                            .disabled(viewModel.isSubmitting)
                            .accessibilityIdentifier("authSignInWithGoogle")

                            Button("Continue with Apple") {
                                Task {
                                    _ = await viewModel.signInWithApple(
                                        identityToken: "ui-test-token",
                                        rawNonce: "ui-test-nonce"
                                    )
                                }
                            }
                            .buttonStyle(GymSecondaryButtonStyle())
                            .disabled(viewModel.isSubmitting)
                            .accessibilityIdentifier("authSignInWithApple")
                        } else {
                            googleSignInButton
                            appleSignInButton
                        }
                    }

                    Button(isResettingPassword ? "Back to sign in" : (isSignIn ? "Create account" : "Already have an account? Sign in")) {
                        if isResettingPassword {
                            isResettingPassword = false
                            isSignIn = true
                        } else {
                            isSignIn.toggle()
                        }
                        password = ""
                        confirmation = ""
                        viewModel.clearFeedback()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GymTheme.accentForeground)
                    .accessibilityIdentifier(isResettingPassword ? "authBackToSignIn" : (isSignIn ? "authShowRegistration" : "authShowSignIn"))

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, GymTheme.spacing16)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .gymPageBackground()
            .toolbar(.hidden, for: .navigationBar)
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

    private var authTitle: String {
        if isResettingPassword { return "Reset password" }
        return isSignIn ? "Welcome back" : "Create account"
    }

    private var authSubtitle: String {
        if isResettingPassword { return "We’ll send reset instructions to your email." }
        return isSignIn ? "Your workout is ready when you are." : "Start your fitness journey."
    }

    private func submit() {
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

    private var googleSignInButton: some View {
        GoogleSignInButton {
            Task { _ = await viewModel.signInWithGoogle() }
        }
        .frame(minHeight: 44)
        .disabled(viewModel.isSubmitting)
        .accessibilityIdentifier("authSignInWithGoogle")
    }
}
