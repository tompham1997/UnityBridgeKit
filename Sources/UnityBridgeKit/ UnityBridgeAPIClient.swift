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
    private let unityCallbackProvider: (UnityCallbackProviderData) -> Void
    
    public init(
        logger: Logger,
        unityCallbackProvider: @escaping (UnityCallbackProviderData) -> Void
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
        performUnityCallback(eventName: target.eventName, id: target.id, encodedJSONRequestData: encodedJSONRequestData)
        
        logger.info("Completed calling request: \(target)")
    }
    
    public func stream(onEventName eventName: String) -> AnyPublisher<Data, Never> {
        return NotificationCenter.default.publisher(for: .init(eventName))
            .compactMap { notification -> Data? in
                guard let userInfo = notification.userInfo else {
                    return nil
                }
                
                guard let jsonData = userInfo["data"] as? String else {
                    return nil
                }
                
                guard let data = jsonData.data(using: .utf8) else {
                    return nil
                }
                
                return data
            }
            .eraseToAnyPublisher()
    }
    
    public func performUnityCallback(eventName: String, id: String, encodedJSONRequestData: String) {
        let providedData = UnityCallbackProviderData(
            eventName: eventName,
            id: id,
            encodedJSONRequestData: encodedJSONRequestData
        )
        unityCallbackProvider(providedData)
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
