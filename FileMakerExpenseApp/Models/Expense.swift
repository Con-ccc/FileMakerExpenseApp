import Foundation
import SwiftData

@Model
final class Expense {
    var name: String
    var amount: Double
    var date: Date
    var isPaid: Bool
    var category: ExpenseCategory
    
    init(
        name: String = "",
        amount: Double = 0.0,
        date: Date = .now,
        isPaid: Bool = false,
        category: ExpenseCategory = .other
    ) {
        self.name = name
        self.amount = amount
        self.date = date
        self.isPaid = isPaid
        self.category = category
    }
    
    func togglePaidStatus(balanceInfo: BalanceInfo) {
        balanceInfo.updateForExpenseStatusChange(amount: amount, newIsPaid: !isPaid, category: category)
        isPaid.toggle()
    }
}
