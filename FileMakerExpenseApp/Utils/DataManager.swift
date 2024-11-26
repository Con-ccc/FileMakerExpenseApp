import Foundation
import SwiftData

struct ExportedData: Codable {
    var expenses: [ExportedExpense]
    var balanceInfo: ExportedBalanceInfo
}

struct ExportedExpense: Codable {
    let name: String
    let amount: Double
    let date: Date
    let isPaid: Bool
    let category: ExpenseCategory
}

struct ExportedBalanceInfo: Codable {
    let payTotal: Double
    let actualRemaining: Double
    let expenseTotalPaid: Double
    let expenseTotalUnpaid: Double
    let balance: Double
    let overdraw: Double
}

class DataManager {
    static func exportData(expenses: [Expense], balanceInfo: BalanceInfo) -> Data? {
        let exportedExpenses = expenses.map { expense in
            ExportedExpense(
                name: expense.name,
                amount: expense.amount,
                date: expense.date,
                isPaid: expense.isPaid,
                category: expense.category
            )
        }
        
        let exportedBalanceInfo = ExportedBalanceInfo(
            payTotal: balanceInfo.payTotal,
            actualRemaining: balanceInfo.actualRemaining,
            expenseTotalPaid: balanceInfo.expenseTotalPaid,
            expenseTotalUnpaid: balanceInfo.expenseTotalUnpaid,
            balance: balanceInfo.balance,
            overdraw: balanceInfo.overdraw
        )
        
        let exportData = ExportedData(
            expenses: exportedExpenses,
            balanceInfo: exportedBalanceInfo
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    static func importData(_ data: Data) -> ExportedData? {
        return try? JSONDecoder().decode(ExportedData.self, from: data)
    }
} 