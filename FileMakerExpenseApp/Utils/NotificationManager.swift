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
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotifications(for expenses: [Expense]) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        // Remove all pending notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let now = Date()
        
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
                        message: "Due in 3 days"
                    )
                }
            }
            
            // Due bills (on the day)
            if UserDefaults.standard.bool(forKey: NotificationType.dueBills.identifier) {
                if expense.date > now {
                    scheduleNotification(
                        for: expense,
                        at: expense.date,
                        type: .dueBills,
                        message: "Due today"
                    )
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
                        message: "Overdue"
                    )
                }
            }
        }
    }
    
    private func scheduleNotification(for expense: Expense, at date: Date, type: NotificationType, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(type.rawValue): \(expense.name)"
        content.body = "\(message) - Amount: \(expense.amount.formatted(.currency(code: "USD")))"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier).\(expense.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 