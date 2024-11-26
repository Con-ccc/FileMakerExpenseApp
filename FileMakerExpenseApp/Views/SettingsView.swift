import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var expenses: [Expense]
    @Query private var balanceInfo: [BalanceInfo]
    
    @AppStorage("defaultCurrency") private var currency = "USD"
    @AppStorage("budgetAlerts") private var budgetAlerts = true {
        didSet {
            if budgetAlerts {
                BudgetAlertManager.shared.requestNotificationPermission()
            }
        }
    }
    @AppStorage("darkMode") private var darkMode = false
    
    @AppStorage("budget.rent") private var rentBudget = 2000.0
    @AppStorage("budget.utilities") private var utilitiesBudget = 300.0
    @AppStorage("budget.groceries") private var groceriesBudget = 600.0
    @AppStorage("budget.transportation") private var transportationBudget = 400.0
    @AppStorage("budget.entertainment") private var entertainmentBudget = 300.0
    @AppStorage("budget.healthcare") private var healthcareBudget = 200.0
    @AppStorage("budget.other") private var otherBudget = 500.0
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true {
        didSet {
            if notificationsEnabled {
                NotificationManager.shared.requestNotificationPermission()
                NotificationManager.shared.scheduleNotifications(for: expenses)
            }
        }
    }
    
    @AppStorage("notification.upcoming") private var upcomingNotifications = true
    @AppStorage("notification.due") private var dueNotifications = true
    @AppStorage("notification.overdue") private var overdueNotifications = true
    
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var exportData: Data? {
        guard let currentBalance = balanceInfo.first else { return nil }
        return DataManager.exportData(expenses: expenses, balanceInfo: currentBalance)
    }
    
    private var currentBudgets: [ExpenseCategory: Double] {
        [
            .rent: rentBudget,
            .utilities: utilitiesBudget,
            .groceries: groceriesBudget,
            .transportation: transportationBudget,
            .entertainment: entertainmentBudget,
            .healthcare: healthcareBudget,
            .other: otherBudget
        ]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                    
                    Toggle("Budget Alerts", isOn: $budgetAlerts)
                        .onChange(of: budgetAlerts) { oldValue, newValue in
                            if newValue {
                                BudgetAlertManager.shared.requestNotificationPermission()
                                BudgetAlertManager.shared.checkBudgetLimits(
                                    expenses: filterExpensesForCurrentMonth(),
                                    budgets: currentBudgets
                                )
                            }
                        }
                    
                    Toggle("Dark Mode", isOn: $darkMode)
                        .onChange(of: darkMode) { oldValue, newValue in
                            setAppearance(isDark: newValue)
                        }
                }
                
                Section("Monthly Budget Limits") {
                    BudgetField(title: "Rent", value: $rentBudget)
                    BudgetField(title: "Utilities", value: $utilitiesBudget)
                    BudgetField(title: "Groceries", value: $groceriesBudget)
                    BudgetField(title: "Transportation", value: $transportationBudget)
                    BudgetField(title: "Entertainment", value: $entertainmentBudget)
                    BudgetField(title: "Healthcare", value: $healthcareBudget)
                    BudgetField(title: "Other", value: $otherBudget)
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Toggle("Upcoming Bills (3 days before)", isOn: $upcomingNotifications)
                            .onChange(of: upcomingNotifications) { _, _ in
                                NotificationManager.shared.scheduleNotifications(for: expenses)
                            }
                        
                        Toggle("Due Bills", isOn: $dueNotifications)
                            .onChange(of: dueNotifications) { _, _ in
                                NotificationManager.shared.scheduleNotifications(for: expenses)
                            }
                        
                        Toggle("Overdue Bills", isOn: $overdueNotifications)
                            .onChange(of: overdueNotifications) { _, _ in
                                NotificationManager.shared.scheduleNotifications(for: expenses)
                            }
                        
                        Toggle("Budget Alerts", isOn: $budgetAlerts)
                    }
                }
                
                Section("Test Notifications") {
                    if notificationsEnabled {
                        Button("Test Upcoming Bill") {
                            testNotification(.upcomingBills)
                        }
                        Button("Test Due Bill") {
                            testNotification(.dueBills)
                        }
                        Button("Test Overdue Bill") {
                            testNotification(.overdueBills)
                        }
                        Button("Test Budget Alert") {
                            testNotification(.budgetAlerts)
                        }
                    }
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        if exportData != nil {
                            showingExporter = true
                        } else {
                            alertMessage = "No data to export"
                            showingAlert = true
                        }
                    }
                    
                    Button("Import Data") {
                        showingImporter = true
                    }
                    
                    Button("Reset All Data", role: .destructive) {
                        resetAllData()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(darkMode ? .dark : .light)
            .onAppear {
                darkMode = colorScheme == .dark
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: ExpenseDataFile(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "ExpenseData"
            ) { result in
                switch result {
                case .success(let url):
                    alertMessage = "Data exported successfully"
                case .failure(let error):
                    alertMessage = "Export failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    importDataFromURL(url)
                case .failure(let error):
                    alertMessage = "Import failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            .alert("Data Management", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func importDataFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let importedData = DataManager.importData(data) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"])
            }
            
            // Clear existing data
            for expense in expenses {
                modelContext.delete(expense)
            }
            for info in balanceInfo {
                modelContext.delete(info)
            }
            
            // Import new data
            for expenseData in importedData.expenses {
                let expense = Expense(
                    name: expenseData.name,
                    amount: expenseData.amount,
                    date: expenseData.date,
                    isPaid: expenseData.isPaid,
                    category: expenseData.category
                )
                modelContext.insert(expense)
            }
            
            let newBalance = BalanceInfo(
                payTotal: importedData.balanceInfo.payTotal,
                actualRemaining: importedData.balanceInfo.actualRemaining,
                expenseTotalPaid: importedData.balanceInfo.expenseTotalPaid,
                expenseTotalUnpaid: importedData.balanceInfo.expenseTotalUnpaid,
                balance: importedData.balanceInfo.balance,
                overdraw: importedData.balanceInfo.overdraw
            )
            modelContext.insert(newBalance)
            
            try modelContext.save()
            alertMessage = "Data imported successfully"
        } catch {
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
        showingAlert = true
    }
    
    private func resetAllData() {
        for expense in expenses {
            modelContext.delete(expense)
        }
        for info in balanceInfo {
            modelContext.delete(info)
        }
        
        let initialBalance = BalanceInfo(
            payTotal: 0.0,
            actualRemaining: 0.0,
            expenseTotalPaid: 0.0,
            expenseTotalUnpaid: 0.0,
            balance: 0.0,
            overdraw: 0.0
        )
        modelContext.insert(initialBalance)
        
        do {
            try modelContext.save()
            alertMessage = "Data reset successfully"
        } catch {
            alertMessage = "Reset failed: \(error.localizedDescription)"
        }
        showingAlert = true
    }
    
    private func setAppearance(isDark: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.overrideUserInterfaceStyle = isDark ? .dark : .light
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
    
    private func testNotification(_ type: NotificationManager.NotificationType) {
        let content = UNMutableNotificationContent()
        
        // Set notification duration to 10 seconds
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        switch type {
        case .upcomingBills:
            content.title = "Upcoming Bills"
            content.subtitle = "Due in next 3 days"
            content.body = """
            📅 Rent Payment
            Amount: $1,500
            Due: In 3 days
            
            📅 Utilities Bill
            Amount: $200
            Due: In 3 days
            
            📅 Internet Service
            Amount: $80
            Due: In 3 days
            """
            
        case .dueBills:
            content.title = "Bills Due Today"
            content.subtitle = "Action required"
            content.body = """
            ⏰ Monthly Rent
            Amount: $1,500
            Status: Due today
            
            ⏰ Phone Bill
            Amount: $45
            Status: Due today
            
            ⏰ Gym Membership
            Amount: $30
            Status: Due today
            """
            
        case .overdueBills:
            content.title = "Overdue Bills"
            content.subtitle = "Immediate attention needed"
            content.body = """
            ⚠️ Water Bill
            Amount: $120
            Status: 2 days overdue
            
            ⚠️ Electricity
            Amount: $150
            Status: 1 day overdue
            
            ⚠️ Cable TV
            Amount: $65
            Status: 3 days overdue
            """
        
        case .budgetAlerts:
            content.title = "Budget Status Update"
            content.subtitle = "Monthly spending overview"
            content.body = """
            📊 Rent Budget
            Spent: $1,700 of $2,000
            Status: 85.0% used
            
            ⚠️ Groceries Budget
            Spent: $580 of $600
            Status: 96.7% used
            
            ⚠️ Entertainment Budget
            Spent: $350 of $300
            Status: 16.7% over budget
            """
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = type.identifier
        content.threadIdentifier = type.threadIdentifier
        
        // Set notification to stay visible for 10 seconds
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,  // Delay before showing
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier).test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("Test notification scheduled for \(type.rawValue)")
            }
        }
    }
}

struct ExpenseDataFile: FileDocument {
    static var readableContentTypes = [UTType.json]
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

struct BudgetField: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Amount", value: $value, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    SettingsView()
} 