import SwiftUI
import Charts
import SwiftData

struct DetailedAnalyticsView: View {
    let expenses: [Expense]
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var selectedChart: ChartType = .cashFlow
    @State private var selectedCategory: ExpenseCategory?
    @State private var isAnimating: Bool = false
    
    enum ChartType: String, CaseIterable {
        case cashFlow = "Cash Flow"
        case spendingHabits = "Spending Habits"
        case categoryTrends = "Category Trends"
        case weeklyPatterns = "Weekly Patterns"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Period Picker
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Chart Type Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            ChartTypeButton(type: type, selected: $selectedChart)
                        }
                    }
                    .padding(.horizontal)
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedChart {
                        case .cashFlow:
                            CashFlowChart(expenses: filterExpenses(expenses),
                                        isAnimating: $isAnimating)
                        case .spendingHabits:
                            SpendingHabitsChart(expenses: filterExpenses(expenses),
                                              selectedCategory: $selectedCategory,
                                              isAnimating: $isAnimating)
                        case .categoryTrends:
                            CategoryTrendsChart(expenses: filterExpenses(expenses),
                                              isAnimating: $isAnimating)
                        case .weeklyPatterns:
                            WeeklyPatternsChart(expenses: filterExpenses(expenses),
                                              isAnimating: $isAnimating)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Detailed Analytics")
            .onAppear {
                withAnimation(.spring()) {
                    isAnimating = true
                }
            }
            .onChange(of: selectedPeriod) {
                withAnimation(.spring()) {
                    isAnimating = true
                }
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = false
                }
            }
        }
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

// Chart Type Selection Button
struct ChartTypeButton: View {
    let type: DetailedAnalyticsView.ChartType
    @Binding var selected: DetailedAnalyticsView.ChartType
    
    var body: some View {
        Button {
            withAnimation(.spring()) {
                selected = type
            }
        } label: {
            Text(type.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selected == type ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(selected == type ? .white : .primary)
        }
    }
}

// I'll continue with the individual chart components in the next messages due to length... 