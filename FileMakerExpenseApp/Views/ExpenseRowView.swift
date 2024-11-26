import SwiftUI
import SwiftData

struct ExpenseRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var balanceInfo: [BalanceInfo]
    
    @State private var showingEditSheet = false
    let expense: Expense
    
    var body: some View {
        HStack {
            // Category Icon
            Image(systemName: expense.category.icon)
                .foregroundColor(Color(expense.category.color))
                .font(.system(size: 24))
                .frame(width: 32)
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.name)
                        .font(.headline)
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(expense.category.color).opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.amount, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundColor(expense.category == .income ? .green : .primary)
                
                if expense.category != .income {
                    Button(expense.isPaid ? "Paid" : "Unpaid") {
                        if let info = balanceInfo.first {
                            expense.togglePaidStatus(balanceInfo: info)
                        }
                    }
                    .font(.caption)
                    .padding(4)
                    .background(expense.isPaid ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(expense.isPaid ? .green : .red)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteExpense()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: .constant(expense))
        }
    }
    
    private func deleteExpense() {
        if let info = balanceInfo.first {
            info.deleteEntry(
                amount: expense.amount,
                isPaid: expense.isPaid,
                category: expense.category
            )
        }
        modelContext.delete(expense)
    }
}

#Preview {
    ExpenseRowView(expense: Expense(
        name: "Sample Expense",
        amount: 99.99,
        date: .now,
        isPaid: true,
        category: .groceries
    ))
    .modelContainer(for: [Expense.self, BalanceInfo.self], inMemory: true)
} 