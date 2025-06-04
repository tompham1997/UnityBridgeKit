//
//  UnityBridgeAPIClientTests.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Testing
import Foundation
import Logging
@testable import UnityBridgeKit


class UnityBridgeAPIClientTests {

    var sut: UnityBridgeAPIClient!
    var decoder: DecoderProtocol!
    
    init() {
        decoder = JSONDecoder()
    }
    
    deinit {
        decoder = nil
        sut = nil
    }
    
    @Test("Test sending the request then received the valid data", arguments: [
        [
            "id": "TEST_REQUEST_DATA",
            "data": #"""
                    {
                        "data": {
                          "title": "tests_structure",
                          "value": 100
                        }
                    }
                    """#
        ]
    ])
    func testUnityBridgeAPIClient_whenSendingValidRequest_thenShouldReceivedExpectedResponse(userInfo: [String: String]?) async throws {
        // Given:
        let target = MockUnityTarget(id: "TEST_REQUEST_DATA")
        
        let sut = makeSUT { data in
            #expect(data.eventName == target.eventName)
            #expect(data.id == target.id)
            NotificationCenter.default.post(name: target.notificationName, object: nil, userInfo: userInfo)
        }
        
        
        // When:
        let data = try await sut.request(target: target)
        let decodedResponse: TestModel = try decoder.decode(key: .data, data: data)
        #expect(decodedResponse == TestModel(title: "tests_structure", value: 100))
    }
}

private extension UnityBridgeAPIClientTests {
    func makeSUT(unityCallbackProvider: sending @escaping @isolated(any) (UnityCallbackProviderData) async throws -> Void) -> UnityBridgeAPIClient {
        return UnityBridgeAPIClient(
            logger: Logger(label: "test"),
            unityCallbackProvider: unityCallbackProvider
        )
    }
}

private extension UnityBridgeAPIClientTests {
    struct TestModel: Equatable, Sendable {
        let title: String
        let value: Int
        
        init(title: String, value: Int) {
            self.title = title
            self.value = value
        }
    }
}

extension UnityBridgeAPIClientTests.TestModel: Decodable {
    private enum CodingKeys: String, CodingKey {
        case title, value
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.value = try container.decode(Int.self, forKey: .value)
    }
}
