//
//  UnityBridgeAPIClientProtocol.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Foundation

public protocol UnityBridgeAPIClientProtocol: Sendable {
    
    func request(target: any UnityBridgeTargetType) async throws(UnityBridgeAPIClientError) -> Data
    
    func requestWithoutWaitingResponse(target: any UnityBridgeTargetType) async throws(UnityBridgeAPIClientError)
    
    func stream(onEventName eventName: String) -> AsyncStream<Data?>
    
    func performUnityCallback(eventName: String, id: String, encodedJSONRequestData: String) async throws
}
