//
//  Observable+Extensions.swift
//  BootLoaderCore
//
//  Created by Tuan Pham on 06/01/2024.
//

import Foundation

public struct GroupsResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    public var groups: CodableType
}

public struct DataResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    public internal(set) var data: CodableType
}

public struct MetaDataResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    
    public internal(set) var meta: CodableType
}

public struct ResultsResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    
    public internal(set) var results: CodableType
}

public struct ParametersResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    
    public internal(set) var parameters: CodableType
}

public struct ErrorResponseWrapper<CodableType: Decodable & Sendable>: Decodable, Sendable {
    public internal(set) var error: CodableType
}

public enum ResponseWrapperKey {
    case groups
    case data
    case meta
    case results
    case none
    case parameters
    case error
}
