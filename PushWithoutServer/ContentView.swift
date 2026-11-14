//
//  ContentView.swift
//  PushWithoutServer
//
//  Created by Itsuki on 2026/11/14.
//

import CloudKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack {
                Button("PUSH") {
                    addItem()
                }
            }
            .navigationTitle("Push Without Server")
        }

    }

    /// any operation using the ItemModel will work
    private func addItem() {
        let newItem = ItemModel(timestamp: Date())
        modelContext.insert(newItem)
        try? modelContext.save()
    }
}

class CloudManager {
    static let containerIdentifier =
        "iCloud.xxx"

    private let container = CKContainer(
        identifier: CloudManager.containerIdentifier
    )

    private var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    var accountStatus: CKAccountStatus = .couldNotDetermine

    init() {
        Task {
            do {
                try await checkAccountStatus()
                guard self.accountStatus != .available else {
                    return
                }
                try await self.addQuerySubscription()
            } catch {
                print("Error: ", error.localizedDescription)
            }
        }
    }

    private func checkAccountStatus() async throws {
        self.accountStatus = try await container.accountStatus()
        print("Account status: \(accountStatus.stringRepresentation)")
    }

    /// subscribe to the full database
    /// Use this if the push notification is expected to trigger for more than one record type AND does not need information on individual fields
    private func addDatabaseSubscription() async throws {
        print("\(#function)")

        /// https://developer.apple.com/documentation/cloudkit/cksubscription/notificationinfo-swift.class
        let notificationInfo = CKSubscription.NotificationInfo()
        /// set `shouldSendContentAvailable` to `true` to have the system to wake or launch an app that isn’t currently running
        notificationInfo.shouldSendContentAvailable = true
        /// set any other properties other than `shouldSendContentAvailable`
        /// so that CloudKit treats the notification as high-priority.
        notificationInfo.soundName = "default"
        notificationInfo.title = "New message"
        notificationInfo.shouldBadge = true

        let databaseSubscription = CKDatabaseSubscription(
            subscriptionID: "database.subscription"
        )
        databaseSubscription.notificationInfo = notificationInfo

        /// To  specialize a database subscription to a specific record type,
        /// we can set its `recordType` property accordingly.
        /// `databaseSubscription.recordType = "CD_ItemModel"`
        ///
        /// NOTE: regardless of whether `recordType` is set or not,
        /// `desiredKeys` are not allowed for Database Subscription

        /// After the operation completes, record that state on-device (in UserDefaults, for example). You can then check that state on subsequent launches to prevent unnecessary trips to the server.
        let _ = try await self.privateDatabase.save(
            databaseSubscription
        )
    }

    private func addQuerySubscription() async throws {
        print("\(#function)")

        /// https://developer.apple.com/documentation/cloudkit/cksubscription/notificationinfo-swift.class
        let notificationInfo = CKSubscription.NotificationInfo()
        /// set `shouldSendContentAvailable` to `true` to have the system to wake or launch an app that isn’t currently running
        notificationInfo.shouldSendContentAvailable = true
        /// set any other properties other than `shouldSendContentAvailable`
        /// so that CloudKit treats the notification as high-priority.
        notificationInfo.soundName = "default"
        notificationInfo.desiredKeys = ["CD_timestamp"]
        notificationInfo.titleLocalizationArgs = ["CD_timestamp"]
        /// This can also be written as `%@`
        /// If you use %@ for your substitution variables, CloudKit replaces those variables by traversing the array in order.
        /// If you use variables of the form %n$@, where n is an integer, n represents the index (starting at 1) of the item in the array to use.
        notificationInfo.titleLocalizationKey = "Timestamp: %1$@"
        notificationInfo.shouldBadge = true

        let truePredicate = NSPredicate(format: "TRUEPREDICATE")

        let querySubscription = CKQuerySubscription(
            recordType: "CD_ItemModel",
            predicate: truePredicate,
            subscriptionID: "query.subscription",
            options: [
                .firesOnRecordCreation, .firesOnRecordDeletion,
                .firesOnRecordUpdate,
            ]
        )

        querySubscription.notificationInfo = notificationInfo

        /// After the operation completes, record that state on-device (in UserDefaults, for example). You can then check that state on subsequent launches to prevent unnecessary trips to the server.
        let _ = try await self.privateDatabase.save(
            querySubscription
        )
    }

}

extension CKAccountStatus {
    var stringRepresentation: String {
        switch self {
        case .couldNotDetermine:
            "couldNotDetermine"
        case .available:
            "available"
        case .restricted:
            "restricted"
        case .noAccount:
            "noAccount"
        case .temporarilyUnavailable:
            "temporarilyUnavailable"
        @unknown default:
            "unknown"
        }
    }
}
