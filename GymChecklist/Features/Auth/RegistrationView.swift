import SwiftUI

@MainActor
struct RegistrationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""

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
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("authPassword")
                    SecureField("Confirm password", text: $confirmation)
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("authConfirmPassword")
                } header: {
                    Text("Create your account")
                } footer: {
                    Text("Use at least 6 characters for your password.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("authRegistrationError")
                    }
                }

                Section {
                    Button(viewModel.isRegistering ? "Creating account…" : "Create account") {
                        Task {
                            _ = await viewModel.register(email: email, password: password, confirmation: confirmation)
                            password = ""
                            confirmation = ""
                        }
                    }
                    .disabled(viewModel.isRegistering)
                    .accessibilityIdentifier("authRegister")
                }
            }
            .navigationTitle("Gym Checklist")
            .accessibilityIdentifier("authRegistrationScreen")
        }
        .onDisappear {
            password = ""
            confirmation = ""
        }
    }
}
