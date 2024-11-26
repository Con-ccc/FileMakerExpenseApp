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
                            testBudgetAlert()
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
        let testExpense = Expense(
            name: "Monthly Rent",
            amount: 1500.0,
            date: Date().addingTimeInterval(type == .upcomingBills ? 259200 : 0), // 3 days for upcoming
            isPaid: false,
            category: .rent
        )
        
        let content = UNMutableNotificationContent()
        
        switch type {
        case .upcomingBills:
            content.title = "Upcoming Bill: \(testExpense.name)"
            content.body = "Your rent payment of $1,500 is due in 3 days. Make sure to plan accordingly."
            
        case .dueBills:
            content.title = "Bill Due Today: \(testExpense.name)"
            content.body = "Your rent payment of $1,500 is due today. Please ensure timely payment."
            
        case .overdueBills:
            content.title = "Overdue Bill: \(testExpense.name)"
            content.body = "Your rent payment of $1,500 is overdue. Please pay as soon as possible to avoid late fees."
            
        case .budgetAlerts:
            content.title = "Budget Alert: Rent"
            content.body = "You've spent 85% of your rent budget this month ($1,700 of $2,000)"
        }
        
        content.sound = .default
        content.badge = 1
        
        // Add category for custom notification grouping
        content.categoryIdentifier = type.identifier
        
        // Add custom actions based on type
        switch type {
        case .upcomingBills, .dueBills, .overdueBills:
            content.userInfo = [
                "expenseId": "test-expense",
                "amount": testExpense.amount,
                "category": testExpense.category.rawValue
            ]
            
        case .budgetAlerts:
            content.userInfo = [
                "category": "rent",
                "spent": 1700.0,
                "budget": 2000.0
            ]
        }
        
        // Schedule notification for 5 seconds later
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
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
    
    private func testBudgetAlert() {
        // Test different budget scenarios
        let testScenarios = [
            ("Rent", 1700.0, 2000.0, 85.0),
            ("Groceries", 580.0, 600.0, 96.7),
            ("Entertainment", 350.0, 300.0, 116.7)
        ]
        
        // Schedule multiple notifications with different delays
        for (index, scenario) in testScenarios.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Budget Alert: \(scenario.0)"
            
            let percentage = scenario.2 > 0 ? (scenario.1 / scenario.2) * 100 : 0
            
            if percentage > 100 {
                content.title = "Budget Exceeded: \(scenario.0)"
                content.body = String(format: "You've exceeded your %@ budget by %.1f%% (%.2f of %.2f)",
                                    scenario.0,
                                    percentage - 100,
                                    scenario.1,
                                    scenario.2)
            } else {
                content.body = String(format: "You've used %.1f%% of your %@ budget (%.2f of %.2f)",
                                    percentage,
                                    scenario.0,
                                    scenario.1,
                                    scenario.2)
            }
            
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "budget-alert"
            content.userInfo = [
                "category": scenario.0,
                "spent": scenario.1,
                "budget": scenario.2,
                "percentage": percentage
            ]
            
            // Stagger notifications by 2 seconds each
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(5 + (index * 2)),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "budget-alert-test-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling budget alert: \(error.localizedDescription)")
                } else {
                    print("Budget alert scheduled for \(scenario.0)")
                }
            }
        }
    }
    
    private func testAllNotifications() {
        // Test all notification types in sequence
        testNotification(.upcomingBills)
        testNotification(.dueBills)
        testNotification(.overdueBills)
        testBudgetAlert()
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