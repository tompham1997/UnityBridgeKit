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

extension UnityBridgeAPIClientError: Equatable {
    public static func == (lhs: UnityBridgeAPIClientError, rhs: UnityBridgeAPIClientError) -> Bool {
        switch (lhs, rhs) {
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.invalidData, .invalidData):
            return true
            
        case (.invalidRequestData(let lhsTarget), .invalidRequestData(let rhsTarget)):
            return lhsTarget.id == rhsTarget.id
            
        case (.callingRequestWhileClientIsDestroyed, .callingRequestWhileClientIsDestroyed):
            return true
            
        case (.receivedInvalidData, .receivedInvalidData):
            return true
            
        case (.receivedInvalidJSONData(let lhsContent), .receivedInvalidJSONData(let rhsContent)):
            return lhsContent == rhsContent
            
        default:
            return false
        }
    }
}
