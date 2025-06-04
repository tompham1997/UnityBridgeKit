//
//  MockTarget.swift
//  UnityBridgeKit
//
//  Created by Tuan on 5/6/25.
//

import Foundation
import UnityBridgeKit

struct MockUnityTarget: UnityBridgeTargetType {
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    var eventName: String {
        "TEST_REQUEST_DATA"
    }
    
    var parameters: [String : any Sendable]? {
        return [
            "parameter1": "value1",
            "parameter2": 2
        ]
    }
}
