import SwiftUI

struct ExpenseTableView: View {
    let expenses: [Expense]
    
    var body: some View {
        List {
            ForEach(expenses) { expense in
                ExpenseRowView(expense: expense)
            }
        }
    }
}

#Preview {
    let expense = Expense(name: "Sample Expense", amount: 99.99, date: .now, isPaid: true)
    return ExpenseTableView(expenses: [expense])
        .modelContainer(for: Expense.self, inMemory: true)
} 