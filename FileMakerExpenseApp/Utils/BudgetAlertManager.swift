import Foundation
import UserNotifications

class BudgetAlertManager {
    static let shared = BudgetAlertManager()
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func checkBudgetLimits(expenses: [Expense], budgets: [ExpenseCategory: Double]) {
        guard UserDefaults.standard.bool(forKey: "budgetAlerts") else { return }
        
        // Group expenses by category
        let expensesByCategory = Dictionary(grouping: expenses) { $0.category }
        
        for (category, budget) in budgets {
            guard category != .income else { continue }
            
            let spent = expensesByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
            let percentage = (spent / budget) * 100
            
            if percentage >= 80 {
                sendBudgetAlert(
                    category: category,
                    spent: spent,
                    budget: budget,
                    percentage: percentage
                )
            }
        }
    }
    
    private func sendBudgetAlert(category: ExpenseCategory, spent: Double, budget: Double, percentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Budget Alert: \(category.rawValue)"
        content.body = String(format: "You've spent %.1f%% of your %@ budget (%.2f of %.2f)",
                            percentage,
                            category.rawValue,
                            spent,
                            budget)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-alert-\(category.rawValue)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 