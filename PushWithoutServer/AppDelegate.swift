//
//  AppDelegate.swift
//  PushWithoutServer
//
//  Created by Itsuki on 2025/06/01.
//

import CloudKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject {
    let manager = CloudManager()

    /// perform set ups
    func setupAppOnLaunch() {

        #if os(iOS)
            UIApplication.shared.registerForRemoteNotifications()
        #else
            NSApplication.shared.registerForRemoteNotifications()
        #endif

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().setBadgeCount(0)
        requestNotificationPermission()

    }

    func didRegisterForRemoteNotificationsWithDeviceToken(
        deviceToken: Data
    ) {
        print(
            "\(#function). \(deviceToken.base64EncodedString())"
        )
    }

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any]
    ) {
        print(#function)
        guard
            let notification = CKNotification(
                fromRemoteNotificationDictionary: userInfo
            )
        else {
            return
        }
        print(notification)
        return
    }

}

#if os(iOS)

    extension AppDelegate: UIApplicationDelegate {

        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication
                .LaunchOptionsKey: Any]? = nil
        ) -> Bool {

            setupAppOnLaunch()
            return true
        }

        // didReceiveRemoteNotification do not trigger correctly on simulators
        @MainActor
        func application(
            _ application: UIApplication,
            didReceiveRemoteNotification userInfo: [AnyHashable: Any]
        ) async -> UIBackgroundFetchResult {
            didReceiveRemoteNotification(userInfo: userInfo)
            return .newData
        }

        func application(
            _ application: UIApplication,
            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
            didRegisterForRemoteNotificationsWithDeviceToken(
                deviceToken: deviceToken
            )
        }

        func application(
            _ application: UIApplication,
            didFailToRegisterForRemoteNotificationsWithError error: Error
        ) {
            print("\(#function). \(error))")
        }
    }

#else

    extension AppDelegate: NSApplicationDelegate {
        func application(
            _ application: NSApplication,
            didFailToRegisterForRemoteNotificationsWithError error: any Error
        ) {

        }

        func application(
            _ application: NSApplication,
            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
            didRegisterForRemoteNotificationsWithDeviceToken(
                deviceToken: deviceToken
            )
        }

        func application(
            _ application: NSApplication,
            didReceiveRemoteNotification userInfo: [String: Any]
        ) {
            didReceiveRemoteNotification(userInfo: userInfo)
        }

        func applicationDidFinishLaunching(_ notification: Notification) {
            setupAppOnLaunch()
        }

    }

#endif

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Request user permissions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                granted,
                error in
                print("Permission granted: \(granted)")
            }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        print(#function)
        return [[.badge, .sound, .banner, .list]]
    }

    /// handles explicit user interactions (like tapping a notification or action button).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        print(response.notification.request.content)
        // title, body, userInfo(data)
    }
}
