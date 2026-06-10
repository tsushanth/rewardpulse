import StoreKit
import Foundation

// MARK: - StoreKitService (Legacy)
//
// Retained for source compatibility. New code should use StoreKitManager directly.
// StoreKitManager is the canonical StoreKit 2 implementation.

actor StoreKitService {
    static let shared = StoreKitService()
    private init() {}

    /// Forwards to StoreKitManager — maintained for any legacy call sites.
    func restorePurchases() async throws {
        try await StoreKitService.runOnMain {
            try await StoreKitManager.shared.restorePurchases()
        }
    }

    /// Verifies a StoreKit VerificationResult.
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    /// Listens for transaction updates. Call once at app launch.
    /// StoreKitManager already does this internally — this is a no-op to avoid duplicate listeners.
    func listenForTransactionUpdates() async {}

    // MARK: - Private

    private static func runOnMain<T: Sendable>(_ closure: @MainActor @Sendable () async throws -> T) async throws -> T {
        try await MainActor.run { try await closure() }
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}
