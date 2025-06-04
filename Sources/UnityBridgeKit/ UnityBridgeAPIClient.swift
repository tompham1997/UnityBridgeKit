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

public actor UnityBridgeAPIClient {
    private let logger: Logger
    private let unityCallbackProvider: (UnityCallbackProviderData) async throws -> Void
    private var cancellables: Set<AnyCancellable> = []
    
    public init(
        logger: Logger,
        unityCallbackProvider: sending @escaping @isolated(any) (UnityCallbackProviderData) async throws -> Void
    ) {
        self.logger = logger
        self.unityCallbackProvider = unityCallbackProvider
    }
}

extension UnityBridgeAPIClient: UnityBridgeAPIClientProtocol {
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
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                NotificationCenter.default.publisher(for: target.notificationName, object: nil)
                    .sink { [weak self] notification in
                        guard let self else {
                            continuation.resume(throwing: UnityBridgeAPIClientError.callingRequestWhileClientIsDestroyed)
                            return
                        }
                        
                        guard let userInfo = notification.userInfo else {
                            continuation.resume(throwing: UnityBridgeAPIClientError.receivedInvalidData)
                            return
                        }
                        
                        guard let id = userInfo["id"] as? String, id.isNotEmpty, id == target.id else {
                            return
                        }
                        
                        guard let jsonData = userInfo["data"] as? String, jsonData.isNotEmpty else {
                            continuation.resume(throwing: UnityBridgeAPIClientError.receivedInvalidData)
                            return
                        }
                        
                        logger.info("Received JSON data: \(jsonData)")
                        
                        guard let data = jsonData.data(using: .utf8) else {
                            continuation.resume(throwing: UnityBridgeAPIClientError.receivedInvalidJSONData(content: jsonData))
                            return
                        }
                        
                        continuation.resume(with: .success(data))
                    }
                    .store(in: &cancellables)
            }
            
        } catch let error as UnityBridgeAPIClientError {
            throw error
        } catch {
            throw UnityBridgeAPIClientError.unknownError(error)
        }
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
    
    public func stream(onEventName: String) -> AsyncThrowingStream<Data, UnityBridgeAPIClientError> {
        fatalError()
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
}
