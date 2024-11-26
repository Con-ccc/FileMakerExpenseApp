import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    enum NotificationType: String, CaseIterable {
        case upcomingBills = "Upcoming Bills"
        case dueBills = "Due Bills"
        case overdueBills = "Overdue Bills"
        case budgetAlerts = "Budget Alerts"
        
        var identifier: String {
            switch self {
            case .upcomingBills: return "notification.upcoming"
            case .dueBills: return "notification.due"
            case .overdueBills: return "notification.overdue"
            case .budgetAlerts: return "notification.budget"
            }
        }
        
        var threadIdentifier: String {
            switch self {
            case .upcomingBills: return "group.upcoming"
            case .dueBills: return "group.due"
            case .overdueBills: return "group.overdue"
            case .budgetAlerts: return "group.budget"
            }
        }
        
        var summaryFormat: String {
            switch self {
            case .upcomingBills: return "%d upcoming bills"
            case .dueBills: return "%d bills due today"
            case .overdueBills: return "%d overdue bills"
            case .budgetAlerts: return "%d budget alerts"
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.setupNotificationCategories()
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create notification categories with different actions
        let upcomingCategory = UNNotificationCategory(
            identifier: NotificationType.upcomingBills.identifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let dueCategory = UNNotificationCategory(
            identifier: NotificationType.dueBills.identifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let overdueCategory = UNNotificationCategory(
            identifier: NotificationType.overdueBills.identifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let budgetCategory = UNNotificationCategory(
            identifier: NotificationType.budgetAlerts.identifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([
            upcomingCategory,
            dueCategory,
            overdueCategory,
            budgetCategory
        ])
    }
    
    func scheduleNotifications(for expenses: [Expense]) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        // Remove all pending notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Group expenses by category for summary
        var upcomingCount = 0
        var dueCount = 0
        var overdueCount = 0
        
        for expense in expenses {
            guard expense.category != .income else { continue }
            
            // Skip if this type of notification is disabled
            if !UserDefaults.standard.bool(forKey: NotificationType.upcomingBills.identifier) &&
               !UserDefaults.standard.bool(forKey: NotificationType.dueBills.identifier) &&
               !UserDefaults.standard.bool(forKey: NotificationType.overdueBills.identifier) {
                continue
            }
            
            // Upcoming bills (3 days before)
            if UserDefaults.standard.bool(forKey: NotificationType.upcomingBills.identifier) {
                let upcomingDate = calendar.date(byAdding: .day, value: -3, to: expense.date)!
                if upcomingDate > now {
                    scheduleNotification(
                        for: expense,
                        at: upcomingDate,
                        type: .upcomingBills,
                        message: "Due in 3 days",
                        groupId: String(calendar.component(.day, from: upcomingDate))
                    )
                    upcomingCount += 1
                }
            }
            
            // Due bills (on the day)
            if UserDefaults.standard.bool(forKey: NotificationType.dueBills.identifier) {
                if expense.date > now {
                    scheduleNotification(
                        for: expense,
                        at: expense.date,
                        type: .dueBills,
                        message: "Due today",
                        groupId: String(calendar.component(.day, from: expense.date))
                    )
                    dueCount += 1
                }
            }
            
            // Overdue bills (1 day after)
            if UserDefaults.standard.bool(forKey: NotificationType.overdueBills.identifier) && !expense.isPaid {
                let overdueDate = calendar.date(byAdding: .day, value: 1, to: expense.date)!
                if overdueDate > now {
                    scheduleNotification(
                        for: expense,
                        at: overdueDate,
                        type: .overdueBills,
                        message: "Overdue",
                        groupId: String(calendar.component(.day, from: overdueDate))
                    )
                    overdueCount += 1
                }
            }
        }
        
        // Schedule summary notifications if needed
        if upcomingCount > 1 {
            scheduleSummaryNotification(type: .upcomingBills, count: upcomingCount)
        }
        if dueCount > 1 {
            scheduleSummaryNotification(type: .dueBills, count: dueCount)
        }
        if overdueCount > 1 {
            scheduleSummaryNotification(type: .overdueBills, count: overdueCount)
        }
    }
    
    private func scheduleNotification(
        for expense: Expense,
        at date: Date,
        type: NotificationType,
        message: String,
        groupId: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(type.rawValue): \(expense.name)"
        content.body = "\(message) - Amount: \(expense.amount.formatted(.currency(code: "USD")))"
        content.sound = .default
        content.threadIdentifier = type.threadIdentifier
        content.categoryIdentifier = type.identifier
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier).\(expense.id).\(groupId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleSummaryNotification(type: NotificationType, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = type.rawValue
        content.body = String(format: type.summaryFormat, count)
        content.sound = .default
        content.threadIdentifier = type.threadIdentifier
        content.categoryIdentifier = type.identifier
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier).summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 