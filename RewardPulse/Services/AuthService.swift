import AuthenticationServices
import Foundation

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    private override init() {}

    @Published var isSignedIn = false
    @Published var currentUserId: String?

    private var signInContinuation: CheckedContinuation<ASAuthorization, Error>?

    func signInWithApple() async throws -> String {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            self.signInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let userId = credential.user
        if let tokenData = credential.identityToken,
           let token = String(data: tokenData, encoding: .utf8) {
            try KeychainService.save(token, for: .sessionToken)
        }

        isSignedIn = true
        currentUserId = userId
        return userId
    }

    func checkSignInStatus() async {
        guard let userId = currentUserId else { return }
        let provider = ASAuthorizationAppleIDProvider()
        let state = try? await provider.credentialState(forUserID: userId)
        isSignedIn = (state == .authorized)
    }

    func signOut() {
        KeychainService.delete(.sessionToken)
        isSignedIn = false
        currentUserId = nil
    }

    func deleteAccount() async throws {
        try await APIService.shared.deleteAccount()
        KeychainService.delete(.sessionToken)
        KeychainService.delete(.paypalEmail)
        isSignedIn = false
        currentUserId = nil
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            signInContinuation?.resume(returning: authorization)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        Task { @MainActor in
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
        }
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case signInFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:   return "Invalid Sign In with Apple credential."
        case .signInFailed(let msg): return "Sign in failed: \(msg)"
        }
    }
}
