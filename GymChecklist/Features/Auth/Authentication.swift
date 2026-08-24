import Combine
import FirebaseAuth
import Foundation

struct AuthenticatedUser: Equatable {
    let id: UserID
}

enum RegistrationError: Error, Equatable {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case networkUnavailable
    case unavailable

    var message: String {
        switch self {
        case .emailAlreadyInUse: return "An account already uses this email."
        case .invalidEmail: return "Enter a valid email address."
        case .weakPassword: return "Use a password with at least 6 characters."
        case .invalidCredentials: return "Email or password is incorrect."
        case .networkUnavailable: return "An internet connection is needed to continue."
        case .unavailable: return "We could not create your account. Please try again."
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
    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation
    func register(email: String, password: String) async throws -> AuthenticatedUser
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func sendPasswordReset(email: String) async throws
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
#if DEBUG
        if FirebaseBootstrap.isRunningTests() {
            return UITestAuthenticationService()
        }
#endif
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
        auth.currentUser.map { AuthenticatedUser(id: UserID(rawValue: $0.uid)) }
    }

    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation {
        let handle = auth.addStateDidChangeListener { _, user in
            let authenticatedUser = user.map { AuthenticatedUser(id: UserID(rawValue: $0.uid)) }
            Task { @MainActor in observer(authenticatedUser) }
        }
        return FirebaseAuthenticationObservation { [weak auth] in
            auth?.removeStateDidChangeListener(handle)
        }
    }

    func register(email: String, password: String) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: Self.map(error))
                } else if let user = result?.user {
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid)))
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
                    continuation.resume(returning: AuthenticatedUser(id: UserID(rawValue: user.uid)))
                } else {
                    continuation.resume(throwing: RegistrationError.unavailable)
                }
            }
        }
    }

    func signOut() throws { try auth.signOut() }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.sendPasswordReset(withEmail: email) { error in
                if let error { continuation.resume(throwing: Self.map(error)) }
                else { continuation.resume() }
            }
        }
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
}

@MainActor
private final class FirebaseAuthenticationObservation: AuthenticationObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}

#if DEBUG
@MainActor
private final class UITestAuthenticationService: AuthenticationService {
    private var observers: [UUID: @MainActor (AuthenticatedUser?) -> Void] = [:]
    private(set) var currentUser: AuthenticatedUser?
    private let registrationError: RegistrationError?

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        registrationError = environment["UITEST_REGISTRATION_ERROR"] == "emailInUse" ? .emailAlreadyInUse : nil
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

    func signOut() throws {
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func sendPasswordReset(email: String) async throws {}
}
#endif
