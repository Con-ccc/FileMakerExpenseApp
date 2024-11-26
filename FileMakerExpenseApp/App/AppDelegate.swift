import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        
        // Configure notification presentation options
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                
                // Configure notification content
                let category = UNNotificationCategory(
                    identifier: "expense_notification",
                    actions: [],
                    intentIdentifiers: [],
                    hiddenPreviewsBodyPlaceholder: "",
                    options: [.customDismissAction, .allowAnnouncement]
                )
                
                center.setNotificationCategories([category])
                
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
        
        return true
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Configure how notifications are presented
        let options: UNNotificationPresentationOptions = [
            .banner,    // Show banner
            .list,      // Show in notification center
            .sound,     // Play sound
            .badge      // Update badge
        ]
        
        completionHandler(options)
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Configure expanded view when notification is tapped
        let content = response.notification.request.content
        
        // Create expanded notification content
        let expandedContent = UNMutableNotificationContent()
        expandedContent.title = content.title
        expandedContent.subtitle = content.subtitle
        expandedContent.body = content.body
        expandedContent.sound = content.sound
        expandedContent.badge = content.badge
        expandedContent.categoryIdentifier = "expense_notification"
        
        // Request expanded presentation
        if #available(iOS 14.0, *) {
            expandedContent.targetContentIdentifier = "expanded_view"
        }
        
        // Schedule expanded notification
        let request = UNNotificationRequest(
            identifier: response.notification.request.identifier + "_expanded",
            content: expandedContent,
            trigger: nil
        )
        
        center.add(request)
        completionHandler()
    }
} 