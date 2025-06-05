//
//   UnityBridgeAPIClient.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Foundation
import Logging
@preconcurrency import Combine

public struct UnityCallbackProviderData: Sendable {
    public let eventName: String
    public let id: String
    public let encodedJSONRequestData: String
    
    public init(eventName: String, id: String, encodedJSONRequestData: String) {
        self.eventName = eventName
        self.id = id
        self.encodedJSONRequestData = encodedJSONRequestData
    }
}

public class UnityBridgeAPIClient {
    private let logger: Logger
    private let unityCallbackProvider: (UnityCallbackProviderData) async throws -> Void
    
    public init(
        logger: Logger,
        unityCallbackProvider: sending @escaping @isolated(any) (UnityCallbackProviderData) async throws -> Void
    ) {
        self.logger = logger
        self.unityCallbackProvider = unityCallbackProvider
    }
}

extension UnityBridgeAPIClient: UnityBridgeAPIClientProtocol, @unchecked Sendable {
    public func request(target: any UnityBridgeTargetType) async throws(UnityBridgeAPIClientError) -> Data {
        logger.info("Started calling request: \(target)")
        let encodedJSONRequestData = try getEncodedJSONRequestData(target: target)
        defer {
            logger.info("Completed calling request: \(target)")
        }
        
        Task {
            try await performWithSmallestDelay {
                try await performUnityCallback(eventName: target.eventName, id: target.id, encodedJSONRequestData: encodedJSONRequestData)
            }
        }
        
        let notifications = NotificationCenter.default.notifications(named: target.notificationName)
        guard let notification = await notifications.first(where: { notification in checkIsValidNotificationEvent(notification, forTarget: target)}) else {
            throw UnityBridgeAPIClientError.receivedInvalidData
        }
        
        return try parseNotificationResponse(notification)
    }
    
    public func requestWithoutWaitingResponse(target: any UnityBridgeTargetType) async throws(UnityBridgeAPIClientError) {
        logger.info("Started calling request: \(target)")
        
        let encodedJSONRequestData = try getEncodedJSONRequestData(target: target)
        do {
            try await performUnityCallback(eventName: target.eventName, id: target.id, encodedJSONRequestData: encodedJSONRequestData)
        } catch {
            throw .unknownError(error)
        }
        
        logger.info("Completed calling request: \(target)")
    }
    
    public func stream(onEventName eventName: String) -> AsyncStream<Data?> {
        AsyncStream { continuation in
            let task = Task {
                for await notification in NotificationCenter.default.notifications(named: .init(eventName)) {
                    let data = try? parseNotificationResponse(notification)
                    continuation.yield(data)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    public func performUnityCallback(eventName: String, id: String, encodedJSONRequestData: String) async throws {
        let providedData = UnityCallbackProviderData(
            eventName: eventName,
            id: id,
            encodedJSONRequestData: encodedJSONRequestData
        )
        try await unityCallbackProvider(providedData)
    }
}

private extension UnityBridgeAPIClient {
    func getEncodedJSONRequestData(target: any UnityBridgeTargetType) throws(UnityBridgeAPIClientError) -> String {
        do {
            return try target.encodedToJSONString()
        } catch _ as UnityBridgeTargetError {
            throw .invalidRequestData(target: target)
        } catch {
            throw .unknownError(error)
        }
    }
    
    func performWithSmallestDelay(nanoseconds: Int = 100_000_000, operation: sending () async throws -> Void) async throws {
        try await Task.sleep(for: .nanoseconds(nanoseconds))
        try await operation()
    }
    
    func parseNotificationResponse(_ notification: Notification) throws(UnityBridgeAPIClientError) -> Data {
        guard let jsonData = notification.userInfo?["data"] as? String, jsonData.isNotEmpty else {
            throw UnityBridgeAPIClientError.receivedInvalidData
        }
        
        logger.info("Received JSON data: \(jsonData)")
        
        guard let data = jsonData.data(using: .utf8) else {
            throw UnityBridgeAPIClientError.receivedInvalidJSONData(content: jsonData)
        }
        
        return data
    }
    
    func checkIsValidNotificationEvent(_ notification: Notification, forTarget target: any UnityBridgeTargetType) -> Bool {
        guard let userInfo = notification.userInfo else {
            return false
        }
        guard let id = userInfo["id"] as? String, id.isNotEmpty, id == target.id else {
            return false
        }
        
        return true
    }
}
