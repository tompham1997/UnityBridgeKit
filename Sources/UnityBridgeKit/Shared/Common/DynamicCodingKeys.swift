//
//  DynamicCodingKeys.swift
//  BootLoaderAPIClient
//
//  Created by tom.pham on 21/8/24.
//

struct DynamicCodingKeys: CodingKey {
    
    var stringValue: String
    var intValue: Int? { return nil }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}
