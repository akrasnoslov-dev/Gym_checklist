import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation
import GoogleSignIn
import Security
import UIKit

struct AuthenticatedUser: Equatable {
    let id: UserID
    /// Display-only account context. It is never persisted with workout data.
    let email: String?

    init(id: UserID, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

enum RegistrationError: Error, Equatable {
    case signInCancelled
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case networkUnavailable
    case unavailable

    var message: String {
        switch self {
        case .signInCancelled: return ""
        case .emailAlreadyInUse: return "An account already uses this email."
        case .invalidEmail: return "Enter a valid email address."
        case .weakPassword: return "Use a password with at least 6 characters."
        case .invalidCredentials: return "Email or password is incorrect."
        case .networkUnavailable: return "An internet connection is needed to continue."
        case .unavailable: return "We could not create your account. Please try again."
        }
    }
}

enum AccountDeletionError: Error, Equatable {
    case requiresRecentAuthentication
    case unavailable

    var message: String {
        switch self {
        case .requiresRecentAuthentication:
            return "For security, sign in again and then retry account deletion."
        case .unavailable:
            return "Couldn’t delete your account. You’re still signed in. Try again."
        }
    }
}

@MainActor
protocol AuthenticationObservation: AnyObject {
    func cancel()
}

@MainActor
protocol AuthenticationService: AnyObject {
    var currentUser: AuthenticatedUser? { get }
    var requiresAppleTokenRevocationForAccountDeletion: Bool { get }
    var requiresGoogleReauthenticationForAccountDeletion: Bool { get }
    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation
    func register(email: String, password: String) async throws -> AuthenticatedUser
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func signInWithGoogle() async throws -> AuthenticatedUser
    func signInWithApple(identityToken: String, rawNonce: String) async throws -> AuthenticatedUser
    func sendPasswordReset(email: String) async throws
    func deleteAccount() async throws
    func deleteAccountWithAppleReauthentication(
        identityToken: String,
        rawNonce: String,
        authorizationCode: String
    ) async throws
    func deleteAccountWithGoogleReauthentication() async throws
    func signOut() throws
}

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published private(set) var currentUser: AuthenticatedUser?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSubmitting = false
    @Published private(set) var isResolving = true
    @Published private(set) var passwordResetMessage: String?

    private let service: AuthenticationService
    private let analytics: AnalyticsTracking
    private var observation: AuthenticationObservation?

    init(service: AuthenticationService, analytics: AnalyticsTracking = NoOpAnalyticsTracker()) {
        self.service = service
        self.analytics = analytics
        observation = service.observeAuthentication { [weak self] user in
            let previousUserID = self?.currentUser?.id
            self?.currentUser = user
            self?.isResolving = false
            if previousUserID != user?.id {
                self?.clearFeedback()
            }
        }
    }

    deinit { MainActor.assumeIsolated { observation?.cancel() } }

    @discardableResult
    func register(email: String, password: String, confirmation: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Enter a valid email address."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Use a password with at least 6 characters."
            return false
        }
        guard password == confirmation else {
            errorMessage = "Passwords do not match."
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await service.register(email: trimmedEmail, password: password)
            analytics.log(.signUp)
            return true
        } catch let error as RegistrationError {
            errorMessage = error.message
            return false
        } catch {
            errorMessage = RegistrationError.unavailable.message
            return false
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Enter a valid email address."
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Enter your password."
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await service.signIn(email: trimmedEmail, password: password)
            analytics.log(.login)
            return true
        } catch let error as RegistrationError {
            errorMessage = error.message
            return false
        } catch {
            errorMessage = RegistrationError.unavailable.message
            return false
        }
    }

    @discardableResult
    func signInWithGoogle() async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await service.signInWithGoogle()
            analytics.log(.login)
            return true
        } catch RegistrationError.signInCancelled {
            return false
        } catch {
            errorMessage = "We could not sign you in with Google. Please try again."
            return false
        }
    }

    @discardableResult
    func signInWithApple(identityToken: String, rawNonce: String) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await service.signInWithApple(identityToken: identityToken, rawNonce: rawNonce)
            analytics.log(.login)
            return true
        } catch RegistrationError.signInCancelled {
            return false
        } catch {
            errorMessage = "We could not sign you in with Apple. Please try again."
            return false
        }
    }

    func handleAppleSignInFailure(_ error: Error) {
        errorMessage = AppleSignInRequest.isCancellation(error)
            ? nil
            : "We could not sign you in with Apple. Please try again."
    }

    func handleAppleAccountDeletionVerificationFailure() {
        errorMessage = "We couldn’t verify your Apple account. You’re still signed in. Try again."
    }

    @discardableResult
    func deleteAccount() async -> Bool {
        return await performAccountDeletion { try await service.deleteAccount() }
    }

    @discardableResult
    func deleteAccountWithAppleReauthentication(
        identityToken: String,
        rawNonce: String,
        authorizationCode: String
    ) async -> Bool {
        return await performAccountDeletion {
            try await service.deleteAccountWithAppleReauthentication(
                identityToken: identityToken,
                rawNonce: rawNonce,
                authorizationCode: authorizationCode
            )
        }
    }

    @discardableResult
    func deleteAccountWithGoogleReauthentication() async -> Bool {
        await performAccountDeletion {
            try await service.deleteAccountWithGoogleReauthentication()
        }
    }

    var requiresAppleTokenRevocationForAccountDeletion: Bool {
        service.requiresAppleTokenRevocationForAccountDeletion
    }

    var requiresGoogleReauthenticationForAccountDeletion: Bool {
        service.requiresGoogleReauthenticationForAccountDeletion
    }

    @discardableResult
    private func performAccountDeletion(_ operation: () async throws -> Void) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await operation()
            currentUser = nil
            isResolving = false
            clearFeedback()
            return true
        } catch let error as AccountDeletionError {
            errorMessage = error.message
            return false
        } catch RegistrationError.signInCancelled {
            return false
        } catch {
            errorMessage = AccountDeletionError.unavailable.message
            return false
        }
    }

    func signOut() {
        do {
            try service.signOut()
            currentUser = nil
            isResolving = false
            clearFeedback()
        } catch {
            errorMessage = "We could not sign you out. Please try again."
        }
    }

    func clearError() { errorMessage = nil }

    func clearFeedback() {
        errorMessage = nil
        passwordResetMessage = nil
    }

    @discardableResult
    func sendPasswordReset(email: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else { errorMessage = "Enter a valid email address."; return false }
        isSubmitting = true
        errorMessage = nil
        passwordResetMessage = nil
        defer { isSubmitting = false }
        do {
            try await service.sendPasswordReset(email: trimmedEmail)
            passwordResetMessage = "If an account matches this email, we’ll send reset instructions."
            return true
        } catch let error as RegistrationError where error == .networkUnavailable {
            errorMessage = "An internet connection is needed to continue."
            return false
        } catch {
            errorMessage = "We could not send reset instructions. Please try again."
            return false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !email.contains(where: \.isWhitespace)
    }
}

@MainActor
enum AuthenticationServiceFactory {
    static func makeDefault() -> AuthenticationService {
        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
            return UITestAuthenticationService()
        }
        return FirebaseAuthenticationService()
    }
}

@MainActor
private final class FirebaseAuthenticationService: AuthenticationService {
    private let auth: Auth

    init(auth: Auth = .auth()) {
        self.auth = auth
    }

    var currentUser: AuthenticatedUser? {
        auth.currentUser.map { AuthenticatedUser(id: UserID(rawValue: $0.uid), email: $0.email) }
    }

    var requiresAppleTokenRevocationForAccountDeletion: Bool {
        auth.currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) == true
    }

    var requiresGoogleReauthenticationForAccountDeletion: Bool {
        auth.currentUser?.providerData.contains(where: { $0.providerID == "google.com" }) == true
    }

    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation {
        let handle = auth.addStateDidChangeListener { _, user in
            let authenticatedUser = user.map { AuthenticatedUser(id: UserID(rawValue: $0.uid), email: $0.email) }
            Task { @MainActor in observer(authenticatedUser) }
        }
        return FirebaseAuthenticationObservation { [weak auth] in
            auth?.removeStateDidChangeListener(handle)
        }
    }

    func register(email: String, password: String) async throws -> AuthenticatedUser {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthenticatedUser, Error>) in
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else if let user = result?.user {
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid), email: user.email))
                } else {
                    continuation.resume(throwing: RegistrationError.unavailable)
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            auth.signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else if let user = result?.user {
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid), email: user.email))
                } else {
                    continuation.resume(throwing: RegistrationError.unavailable)
                }
            }
        }
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws -> AuthenticatedUser {
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: rawNonce
        )
        return try await withCheckedThrowingContinuation { continuation in
            auth.signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else if let user = result?.user {
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid), email: user.email))
                } else {
                    continuation.resume(throwing: RegistrationError.unavailable)
                }
            }
        }
    }

    func signInWithGoogle() async throws -> AuthenticatedUser {
        let credential = try await freshGoogleCredential()
        return try await withCheckedThrowingContinuation { continuation in
            auth.signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else if let user = result?.user {
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid), email: user.email))
                } else {
                    continuation.resume(throwing: RegistrationError.unavailable)
                }
            }
        }
    }

    func signOut() throws {
        try auth.signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.sendPasswordReset(withEmail: email) { error in
                if let error { continuation.resume(throwing: Self.map(error)) }
                else { continuation.resume() }
            }
        }
    }

    func deleteAccount() async throws {
        guard !requiresAppleTokenRevocationForAccountDeletion else {
            throw AccountDeletionError.requiresRecentAuthentication
        }
        try await FirebaseAccountDeletionCallable().deleteCurrentAccount()
    }

    func deleteAccountWithAppleReauthentication(
        identityToken: String,
        rawNonce: String,
        authorizationCode: String
    ) async throws {
        guard let user = auth.currentUser,
              user.providerData.contains(where: { $0.providerID == "apple.com" }) else {
            throw AccountDeletionError.unavailable
        }
        let expectedUserID = user.uid
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: rawNonce
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        guard auth.currentUser?.uid == expectedUserID else {
            throw AccountDeletionError.unavailable
        }
        try await auth.revokeToken(withAuthorizationCode: authorizationCode)
        guard auth.currentUser?.uid == expectedUserID else {
            throw AccountDeletionError.unavailable
        }
        _ = try await user.getIDToken(forcingRefresh: true)
        guard auth.currentUser?.uid == expectedUserID else {
            throw AccountDeletionError.unavailable
        }
        try await FirebaseAccountDeletionCallable().deleteCurrentAccount()
    }

    func deleteAccountWithGoogleReauthentication() async throws {
        guard let user = auth.currentUser,
              user.providerData.contains(where: { $0.providerID == "google.com" }) else {
            throw AccountDeletionError.unavailable
        }
        let expectedUserID = user.uid
        let credential = try await freshGoogleCredential()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        guard auth.currentUser?.uid == expectedUserID else {
            throw AccountDeletionError.unavailable
        }
        _ = try await user.getIDToken(forcingRefresh: true)
        guard auth.currentUser?.uid == expectedUserID else {
            throw AccountDeletionError.unavailable
        }
        try await FirebaseAccountDeletionCallable().deleteCurrentAccount()
    }

    private static func map(_ error: Error) -> RegistrationError {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else { return .unavailable }
        switch code {
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .invalidEmail: return .invalidEmail
        case .weakPassword: return .weakPassword
        case .networkError: return .networkUnavailable
        case .wrongPassword, .userNotFound, .invalidCredential: return .invalidCredentials
        default: return .unavailable
        }
    }

    private func freshGoogleCredential() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let presenter = Self.activePresentationController() else {
            throw RegistrationError.unavailable
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw RegistrationError.unavailable
            }
            return GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        } catch let error as NSError
            where error.domain == kGIDSignInErrorDomain
                && error.code == Self.googleSignInCancellationErrorCode {
            throw RegistrationError.signInCancelled
        } catch {
            throw RegistrationError.unavailable
        }
    }

    // Google Sign-In documents cancellation as kGIDSignInErrorCodeCanceled (-5).
    // The Swift enum is not exported by the SDK package's module interface.
    private static let googleSignInCancellationErrorCode = -5

    @MainActor
    private static func activePresentationController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)
        else { return nil }
        return visibleViewController(from: window.rootViewController)
    }

    private static func visibleViewController(from controller: UIViewController?) -> UIViewController? {
        if let navigation = controller as? UINavigationController {
            return visibleViewController(from: navigation.visibleViewController)
        }
        if let tab = controller as? UITabBarController {
            return visibleViewController(from: tab.selectedViewController)
        }
        if let presented = controller?.presentedViewController {
            return visibleViewController(from: presented)
        }
        return controller
    }
}

private struct FirebaseAccountDeletionCallable {
    func deleteCurrentAccount() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Functions.functions().httpsCallable("deleteAccount").call { _, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func map(_ error: Error) -> AccountDeletionError {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain,
              let code = FunctionsErrorCode(rawValue: nsError.code) else {
            return .unavailable
        }
        return code == .failedPrecondition ? .requiresRecentAuthentication : .unavailable
    }
}

enum AppleSignInRequest {
    static func configure(_ request: ASAuthorizationAppleIDRequest) -> String {
        let rawNonce = randomNonce()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(rawNonce)
        return rawNonce
    }

    static func identityToken(from authorization: ASAuthorization) -> String? {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken else { return nil }
        return String(data: tokenData, encoding: .utf8)
    }

    static func authorizationCode(from authorization: ASAuthorization) -> String? {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let codeData = credential.authorizationCode else { return nil }
        return String(data: codeData, encoding: .utf8)
    }

    static func isCancellation(_ error: Error) -> Bool {
        (error as? ASAuthorizationError)?.code == .canceled
    }

    private static func randomNonce(length: Int = 32) -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var nonce = ""
        var remainingLength = length
        while remainingLength > 0 {
            var random: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess else {
                preconditionFailure("Unable to generate a secure Sign in with Apple nonce.")
            }
            if random < alphabet.count {
                nonce.append(alphabet[Int(random)])
                remainingLength -= 1
            }
        }
        return nonce
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
private final class FirebaseAuthenticationObservation: AuthenticationObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}

@MainActor
private final class UITestAuthenticationService: AuthenticationService {
    private var observers: [UUID: @MainActor (AuthenticatedUser?) -> Void] = [:]
    private(set) var currentUser: AuthenticatedUser?
    private let registrationError: RegistrationError?
    private let accountDeletionError: AccountDeletionError?
    private let requiresAppleTokenRevocation: Bool

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        registrationError = environment["UITEST_REGISTRATION_ERROR"] == "emailInUse" ? .emailAlreadyInUse : nil
        accountDeletionError = environment["UITEST_ACCOUNT_DELETION_ERROR"] == "recentAuthentication"
            ? .requiresRecentAuthentication
            : nil
        requiresAppleTokenRevocation = environment["UITEST_ACCOUNT_DELETION_PROVIDER"] == "apple"
        if environment["UITEST_AUTH_MODE"] != "registration" {
            currentUser = AuthenticatedUser(id: UserID(rawValue: "ui-test-user"))
        }
    }

    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation {
        let id = UUID()
        observers[id] = observer
        observer(currentUser)
        return FirebaseAuthenticationObservation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    var requiresAppleTokenRevocationForAccountDeletion: Bool {
        requiresAppleTokenRevocation
    }

    var requiresGoogleReauthenticationForAccountDeletion: Bool {
        ProcessInfo.processInfo.environment["UITEST_ACCOUNT_DELETION_PROVIDER"] == "google"
    }

    func register(email: String, password: String) async throws -> AuthenticatedUser {
        if let registrationError { throw registrationError }
        let user = AuthenticatedUser(id: UserID(rawValue: "ui-test-registered-user"))
        currentUser = user
        observers.values.forEach { $0(user) }
        return user
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        try await register(email: email, password: password)
    }

    func signInWithGoogle() async throws -> AuthenticatedUser {
        try await register(email: "google-ui-test@example.com", password: "not-used")
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws -> AuthenticatedUser {
        try await register(email: "apple-ui-test@example.com", password: "not-used")
    }

    func deleteAccount() async throws {
        if requiresAppleTokenRevocation { throw AccountDeletionError.requiresRecentAuthentication }
        if let accountDeletionError { throw accountDeletionError }
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func deleteAccountWithAppleReauthentication(
        identityToken: String,
        rawNonce: String,
        authorizationCode: String
    ) async throws {
        guard !identityToken.isEmpty, !rawNonce.isEmpty, !authorizationCode.isEmpty else {
            throw AccountDeletionError.unavailable
        }
        if let accountDeletionError { throw accountDeletionError }
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func deleteAccountWithGoogleReauthentication() async throws {
        if let accountDeletionError { throw accountDeletionError }
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func signOut() throws {
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func sendPasswordReset(email: String) async throws {}
}
