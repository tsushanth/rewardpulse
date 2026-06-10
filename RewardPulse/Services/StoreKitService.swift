import StoreKit
import Foundation

actor StoreKitService {
    static let shared = StoreKitService()
    private init() {}

    private let productIDs: Set<String> = [
        "com.com.appfactory.rewardpulse.subscription.weekly",
        "com.com.appfactory.rewardpulse.subscription.yearly",
        "com.com.appfactory.rewardpulse.subscription.lifetime",
        "com.com.appfactory.rewardpulse.iap.small_iap"
    ]

    private(set) var products: [Product] = []

    func loadProducts() async throws {
        products = try await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .pending:
            return nil
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await RevenueCatService.shared.syncTransaction(transaction)
            await transaction.finish()
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func currentEntitlements() async -> [Transaction] {
        var transactions: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                transactions.append(transaction)
            }
        }
        return transactions
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}
