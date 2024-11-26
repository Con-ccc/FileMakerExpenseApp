import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var balanceInfo: [BalanceInfo]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    let expense: Expense
    
    @State private var name: String
    @State private var amount: Double
    @State private var date: Date
    @State private var isPaid: Bool
    @State private var category: ExpenseCategory
    @State private var showingError = false
    
    init(expense: Binding<Expense>) {
        self.expense = expense.wrappedValue
        self._name = State(initialValue: expense.wrappedValue.name)
        self._amount = State(initialValue: expense.wrappedValue.amount)
        self._date = State(initialValue: expense.wrappedValue.date)
        self._isPaid = State(initialValue: expense.wrappedValue.isPaid)
        self._category = State(initialValue: expense.wrappedValue.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $name)
                
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                
                Toggle("Paid", isOn: $isPaid)
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateExpense()
                    }
                    .disabled(name.isEmpty || amount == 0)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("There was an error updating the expense. Please try again.")
            }
        }
    }
    
    private func updateExpense() {
        if let info = balanceInfo.first {
            // First, reverse the original transaction
            info.deleteEntry(
                amount: expense.amount,
                isPaid: expense.isPaid,
                category: expense.category
            )
            
            // Update the expense properties
            expense.name = name
            expense.amount = amount
            expense.date = date
            expense.isPaid = isPaid
            expense.category = category
            
            // Add the new transaction
            info.updateForNewExpense(
                amount,
                isPaid: isPaid,
                category: category
            )
            
            if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                NotificationManager.shared.scheduleNotifications(for: expenses)
            }
            
            dismiss()
        } else {
            showingError = true
        }
    }
} 