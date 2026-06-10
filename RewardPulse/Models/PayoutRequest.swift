import SwiftData
import Foundation

@Model
final class PayoutRequest {
    var id: UUID
    var amountCents: Int
    var method: PayoutMethod
    var destinationIdentifier: String
    var status: PayoutStatus
    var initiatedAt: Date
    var completedAt: Date?
    var serverTransactionId: String?
    var failureReason: String?

    init(amountCents: Int, method: PayoutMethod, destination: String) {
        self.id = UUID()
        self.amountCents = amountCents
        self.method = method
        self.destinationIdentifier = destination
        self.status = .initiated
        self.initiatedAt = .now
    }

    var amountFormatted: String { String(format: "$%.2f", Double(amountCents) / 100.0) }
}

enum PayoutMethod: String, Codable {
    case paypal, giftCardAmazon, giftCardStarbucks, bankTransfer

    var displayName: String {
        switch self {
        case .paypal:             return "PayPal"
        case .giftCardAmazon:     return "Amazon Gift Card"
        case .giftCardStarbucks:  return "Starbucks Gift Card"
        case .bankTransfer:       return "Bank Transfer"
        }
    }

    var iconName: String {
        switch self {
        case .paypal:             return "p.circle.fill"
        case .giftCardAmazon:     return "shippingbox.fill"
        case .giftCardStarbucks:  return "cup.and.saucer.fill"
        case .bankTransfer:       return "building.columns.fill"
        }
    }
}

enum PayoutStatus: String, Codable {
    case initiated, processing, completed, failed

    var displayText: String {
        switch self {
        case .initiated:  return "Sending…"
        case .processing: return "Processing"
        case .completed:  return "Sent"
        case .failed:     return "Failed"
        }
    }

    var color: String {
        switch self {
        case .initiated:  return "Warning"
        case .processing: return "Warning"
        case .completed:  return "Success"
        case .failed:     return "Error"
        }
    }
}
