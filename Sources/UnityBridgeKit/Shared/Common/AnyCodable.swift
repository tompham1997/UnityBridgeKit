//
//  AnyCodable.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Foundation

/// The `AnyCodable` struct allows encoding and decoding of any Sendable type, including nested arrays and dictionaries.
///  
/// Supported:
/// - Primitive types: `Int`, `Double`, `String`, `Bool`.
/// - Nested arrays of `AnyCodable`.
/// - Nested dictionaries with `String` keys and `AnyCodable` values.
public struct AnyCodable: Codable, Sendable {
    public var value: Sendable
    
    public init(_ value: Sendable) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
            return
        }
        
        if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
            return
        }
        
        if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
            return
        }
        
        if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
            return
        }
        
        if let nestedArray = try? container.decode([AnyCodable].self) {
            self.value = nestedArray.map { $0.value }
            return
        }
        
        if let nestedDictionary = try? container.decode([String: AnyCodable].self) {
            self.value = nestedDictionary.mapValues { $0.value }
            return
        }
        
        throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
            
        case let doubleValue as Double:
            try container.encode(doubleValue)
            
        case let stringValue as String:
            try container.encode(stringValue)
            
        case let boolValue as Bool:
            try container.encode(boolValue)
            
        case let arrayValue as [Sendable]:
            let nestedArray = arrayValue.map { AnyCodable($0) }
            try container.encode(nestedArray)
            
        case let dictionaryValue as [String: Sendable]:
            let nestedDictionary = dictionaryValue.mapValues { AnyCodable($0) }
            try container.encode(nestedDictionary)
            
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
