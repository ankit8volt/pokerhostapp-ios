import Foundation

enum PaymentMethod {
    case cash
    case upi
}

enum PlayerStatus {
    case active
    case checkedOut
}

enum TransactionType {
    case buyIn
    case reBuyIn
    case settlementPayout
    case settlementCollect
}

struct SessionSummary {
    let totalCollected: Decimal
    let collectedByCash: Decimal
    let collectedByUPI: Decimal
    let totalOutstanding: Decimal
    let totalBuyIns: Int
    let playerCount: Int
    let perPlayerBreakdown: [PlayerBreakdown]
}

struct PlayerBreakdown {
    let playerName: String
    let buyInCount: Int
    let amountCollected: Decimal
    let collectedByCash: Decimal
    let collectedByUPI: Decimal
    let outstandingBalance: Decimal
}
