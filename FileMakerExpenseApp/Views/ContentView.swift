import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \BalanceInfo.payTotal) private var balanceInfo: [BalanceInfo]
    
    @State private var showingAddExpense = false
    @State private var selectedTab = 0
    @State private var selectedPeriod: TimePeriod = .thisMonth
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            NavigationStack {
                VStack {
                    HeaderView(balanceInfo: balanceInfo.first ?? BalanceInfo())
                    ExpenseTableView(expenses: expenses)
                }
                .navigationTitle("Expense Tracker")
                .toolbar {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .sheet(isPresented: $showingAddExpense) {
                    AddExpenseView()
                }
            }
            .tabItem {
                Label("Overview", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Dashboard Tab
            FinancialDashboardView(expenses: expenses, selectedPeriod: selectedPeriod)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // Calendar Tab
            CalendarView(expenses: expenses)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)
            
            // Analysis Tab
            GraphTabView(expenses: expenses, selectedPeriod: selectedPeriod)
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            if balanceInfo.isEmpty {
                setupInitialData()
            }
        }
    }
    
    private func setupInitialData() {
        do {
            let initialBalance = BalanceInfo(
                payTotal: 0.0,
                actualRemaining: 0.0,
                expenseTotalPaid: 0.0,
                expenseTotalUnpaid: 0.0,
                balance: 0.0,
                overdraw: 0.0
            )
            modelContext.insert(initialBalance)
            try modelContext.save()
        } catch {
            print("Error setting up initial data: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, BalanceInfo.self], inMemory: true)
} 