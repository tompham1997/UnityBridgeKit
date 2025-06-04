//
//  UnityBridgeAPIClientError.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

public enum UnityBridgeAPIClientError: Error {
    case invalidRequestData(target: any UnityBridgeTargetType)
    case invalidData
    case callingRequestWhileClientIsDestroyed
    case receivedInvalidData
    case receivedInvalidJSONData(content: String)
    case unknownError(Error)
}
