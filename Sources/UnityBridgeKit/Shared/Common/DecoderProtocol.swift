//
//  DecoderProtocol.swift
//  BootLoaderCore
//
//  Created by Tuan Pham on 06/01/2024.
//

import Foundation

/// A protocol that defines a type that can decode values from external representations.
///
/// You can use a decoder to decode any type that conforms to the `Decodable` protocol, including your own custom types.
///
/// For example, to decode a custom type from JSON, create a `JSONDecoder` instance, and call its `decode(_:from:)` method:
///
///     let json = """
///     {
///       "name": "Taylor Swift",
///      "age": 26
///     }
///     """.data(using: .utf8)!
///
///     struct User: Codable {
///         var name: String
///         var age: Int
///     }
///
///    let decoder = JSONDecoder()
///    let user = try decoder.decode(User.self, from: json)
public protocol DecoderProtocol: Sendable {
 
    /// Decode the given data into the provided type.
    ///
    /// - Parameters:
    ///    - type: The type to decode into.
    ///   - data: The data to decode.
    /// - Returns: The decoded value.
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

// MARK: - JSONDecoder

extension JSONDecoder: DecoderProtocol {}

extension DecoderProtocol {
    
    public func decode<DecodeType: Decodable & Sendable>(
        key: ResponseWrapperKey = .none,
        data: Data
    ) throws -> DecodeType {
        do {
            switch key {
            case .groups:
                return try decode(GroupsResponseWrapper<DecodeType>.self, from: data).groups
            case .data:
                return try decode(DataResponseWrapper<DecodeType>.self, from: data).data
                
            case .meta:
                return try decode(MetaDataResponseWrapper<DecodeType>.self, from: data).meta
                
            case .results:
                return try decode(ResultsResponseWrapper<DecodeType>.self, from: data).results
                
            case .none:
                return try decode(DecodeType.self, from: data)
            case .parameters:
                return try decode(ParametersResponseWrapper<DecodeType>.self, from: data).parameters
                
            case .error:
                return try decode(ErrorResponseWrapper<DecodeType>.self, from: data).error
            }
        } catch {
            throw error
        }
    }
}
