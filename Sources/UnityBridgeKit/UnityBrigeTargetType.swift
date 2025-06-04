//
//  UnityBridgeTargetType.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Foundation

public protocol UnityBridgeTargetType: Encodable, Sendable {
    
    var eventName: String { get }
    
    var id: String { get }
    
    var parameters: [String: Sendable]? { get }
    
    var notificationName: Notification.Name { get }
}

// MARK: - NotificationName Convertor

extension UnityBridgeTargetType {
    
    public var parameters: [String: Sendable]? {
        return nil
    }
    
    public var notificationName: Notification.Name {
        let rawValue = "\(eventName)_\(id)"
        return .init(rawValue: rawValue)
    }
}

private enum TargetTypeCodingKeys: String, CodingKey {
    case eventName
    case id
    case parameters
}

public enum UnityBridgeTargetError: Error {
    case invalidRequestFormat
}

public extension UnityBridgeTargetType {
    
    func encodedToJSONString() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        if let jsonString = String(data: data, encoding: .utf8), jsonString.isNotEmpty {
            return jsonString
        }
        
        throw UnityBridgeTargetError.invalidRequestFormat
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: TargetTypeCodingKeys.self)
        
        try container.encode(eventName, forKey: .eventName)
        try container.encode(id, forKey: .id)
        
        if let parameters {
            for (_, _) in parameters {
                var parametersContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .parameters)
                
                for (key, value) in parameters {
                    let dynamicKey = DynamicCodingKeys(stringValue: key)!
                    
                    switch value {
                    case let v as String:
                        try parametersContainer.encode(v, forKey: dynamicKey)
                        
                    case let v as Int:
                        try parametersContainer.encode(v, forKey: dynamicKey)
                        
                    case let v as Double:
                        try parametersContainer.encode(v, forKey: dynamicKey)
                        
                    case let v as Bool:
                        try parametersContainer.encode(v, forKey: dynamicKey)
                        
                    case let v as [String: Any]:
                        let nestedData = try JSONSerialization.data(withJSONObject: v, options: [])
                        let nestedObject = try JSONDecoder().decode([String: AnyCodable].self, from: nestedData)
                        try parametersContainer.encode(nestedObject, forKey: dynamicKey)
                        
                    case let v as [Any]:
                        let nestedData = try JSONSerialization.data(withJSONObject: v, options: [])
                        let nestedArray = try JSONDecoder().decode([AnyCodable].self, from: nestedData)
                        try parametersContainer.encode(nestedArray, forKey: dynamicKey)
                        
                    case  let v as Encodable:
                        try parametersContainer.encode(v, forKey: dynamicKey)
                        
                    default:
                        throw EncodingError.invalidValue(
                            value, EncodingError.Context(
                                codingPath: container.codingPath,
                                debugDescription: "Unsupported type"
                            )
                        )
                    }
                }
            }
        }
    }
}
