import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var balanceInfo: [BalanceInfo]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var name = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var isPaid = false
    @State private var category: ExpenseCategory = .other
    @State private var isIncome = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(isIncome ? "Income Source" : "Expense Name", text: $name)
                
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Toggle("Is Income", isOn: $isIncome)
                    .onChange(of: isIncome) {
                        category = isIncome ? .income : .other
                    }
                
                if !isIncome {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.expenseCategories, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Toggle("Paid", isOn: $isPaid)
                }
            }
            .navigationTitle(isIncome ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(name.isEmpty || amount == 0)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("There was an error saving the entry. Please try again.")
            }
        }
    }
    
    private func addExpense() {
        let expense = Expense(
            name: name,
            amount: amount,
            date: date,
            isPaid: isIncome ? true : isPaid,  // Income is always "paid"
            category: isIncome ? .income : category
        )
        
        modelContext.insert(expense)
        
        if let info = balanceInfo.first {
            info.updateForNewExpense(amount, isPaid: isIncome ? true : isPaid, category: expense.category)
            dismiss()
        } else {
            showingError = true
        }
        
        if UserDefaults.standard.bool(forKey: "budgetAlerts") {
            let budgets: [ExpenseCategory: Double] = [
                .rent: UserDefaults.standard.double(forKey: "budget.rent"),
                .utilities: UserDefaults.standard.double(forKey: "budget.utilities"),
                .groceries: UserDefaults.standard.double(forKey: "budget.groceries"),
                .transportation: UserDefaults.standard.double(forKey: "budget.transportation"),
                .entertainment: UserDefaults.standard.double(forKey: "budget.entertainment"),
                .healthcare: UserDefaults.standard.double(forKey: "budget.healthcare"),
                .other: UserDefaults.standard.double(forKey: "budget.other")
            ]
            
            BudgetAlertManager.shared.checkBudgetLimits(
                expenses: filterExpensesForCurrentMonth(),
                budgets: budgets
            )
        }
        
        if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
            NotificationManager.shared.scheduleNotifications(for: expenses)
        }
    }
    
    private func filterExpensesForCurrentMonth() -> [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return expenses.filter { expense in
            (expense.date >= startOfMonth) && (expense.date <= endOfMonth)
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, BalanceInfo.self], inMemory: true)
} 