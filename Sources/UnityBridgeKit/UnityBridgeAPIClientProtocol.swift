//
//  UnityBridgeAPIClientProtocol.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Foundation

public protocol UnityBridgeAPIClientProtocol: Actor {
    
    func request(target: UnityBridgeTargetType) async throws(UnityBridgeAPIClientError) -> Data
    
    func requestWithoutWaitingResponse(target: UnityBridgeTargetType) async throws(UnityBridgeAPIClientError)
    
    func stream(onEventName: String) -> AsyncThrowingStream<Data, UnityBridgeAPIClientError>
    
    func performUnityCallback(eventName: String, id: String, encodedJSONRequestData: String) async throws
}
