import Foundation
import SwiftData

@Model
final class BalanceInfo {
    var payTotal: Double
    var actualRemaining: Double
    var expenseTotalPaid: Double
    var expenseTotalUnpaid: Double
    var balance: Double
    var overdraw: Double
    
    // Category-specific totals
    var categoryTotals: [String: CategoryTotal]
    
    init(
        payTotal: Double = 0.0,
        actualRemaining: Double = 0.0,
        expenseTotalPaid: Double = 0.0,
        expenseTotalUnpaid: Double = 0.0,
        balance: Double = 0.0,
        overdraw: Double = 0.0
    ) {
        self.payTotal = payTotal
        self.actualRemaining = actualRemaining
        self.expenseTotalPaid = expenseTotalPaid
        self.expenseTotalUnpaid = expenseTotalUnpaid
        self.balance = balance
        self.overdraw = overdraw
        
        // Initialize category totals
        self.categoryTotals = [:]
        ExpenseCategory.allCases.forEach { category in
            self.categoryTotals[category.rawValue] = CategoryTotal()
        }
    }
    
    func updateForNewExpense(_ amount: Double, isPaid: Bool, category: ExpenseCategory) {
        switch category {
        case .income:
            // Income increases available funds
            payTotal += amount
            actualRemaining += amount
            
        case .rent, .utilities, .groceries, .transportation, .entertainment, .healthcare, .other:
            // Handle expenses
            if isPaid {
                // Paid expenses reduce available funds immediately
                expenseTotalPaid += amount
                categoryTotals[category.rawValue]?.paid += amount
                actualRemaining -= amount
            } else {
                // Unpaid expenses only affect potential overdraw
                expenseTotalUnpaid += amount
                categoryTotals[category.rawValue]?.unpaid += amount
            }
        }
        recalculateBalances()
    }
    
    func updateForExpenseStatusChange(amount: Double, newIsPaid: Bool, category: ExpenseCategory) {
        guard category != .income else { return }
        
        if newIsPaid {
            // Converting unpaid to paid
            expenseTotalPaid += amount
            expenseTotalUnpaid -= amount
            categoryTotals[category.rawValue]?.paid += amount
            categoryTotals[category.rawValue]?.unpaid -= amount
            actualRemaining -= amount  // Reduce available funds when paying
        } else {
            // Converting paid to unpaid
            expenseTotalPaid -= amount
            expenseTotalUnpaid += amount
            categoryTotals[category.rawValue]?.paid -= amount
            categoryTotals[category.rawValue]?.unpaid += amount
            actualRemaining += amount  // Restore funds when unpaying
        }
        recalculateBalances()
    }
    
    func deleteEntry(amount: Double, isPaid: Bool, category: ExpenseCategory) {
        switch category {
        case .income:
            // Remove income
            payTotal -= amount
            actualRemaining -= amount
            
        case .rent, .utilities, .groceries, .transportation, .entertainment, .healthcare, .other:
            // Remove expense
            if isPaid {
                expenseTotalPaid -= amount
                categoryTotals[category.rawValue]?.paid -= amount
                actualRemaining += amount  // Restore funds for paid expenses
            } else {
                expenseTotalUnpaid -= amount
                categoryTotals[category.rawValue]?.unpaid -= amount
            }
        }
        recalculateBalances()
    }
    
    func recalculateBalances() {
        // Balance always matches actual remaining funds
        balance = actualRemaining
        
        // Overdraw shows what would happen if all unpaid expenses were paid
        overdraw = actualRemaining - expenseTotalUnpaid
    }
    
    func getTotalForCategory(_ category: ExpenseCategory, isPaid: Bool) -> Double {
        guard let categoryTotal = categoryTotals[category.rawValue] else { return 0 }
        return isPaid ? categoryTotal.paid : categoryTotal.unpaid
    }
}

struct CategoryTotal: Codable {
    var paid: Double = 0.0
    var unpaid: Double = 0.0
} 