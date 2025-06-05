//
//  UnityBridgeAPIClientTests.swift
//  UnityBridgeKit
//
//  Created by Tuan on 4/6/25.
//

import Testing
import Foundation
import Logging
import Combine
@testable import UnityBridgeKit


class UnityBridgeAPIClientTests {
    
    var sut: UnityBridgeAPIClient!
    var decoder: DecoderProtocol!
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        decoder = JSONDecoder()
    }
    
    deinit {
        decoder = nil
        sut = nil
        cancellables.removeAll()
    }
    
    @Test("Test sending the request then received the valid data", arguments: [
        [
            "id": "TEST_REQUEST_DATA_1",
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
        let target = MockUnityTarget(id: "TEST_REQUEST_DATA_1")
        
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
    
    @Test("Test throw receivedInvalidData Error when received invalid userInfo")
    func testUnityBridgeAPIClient_whenReceivedInvalidUserInfo_thenShouldThrowReceivedInvalidDataError() async throws {
        let target = MockUnityTarget(id: "TEST_REQUEST_DATA_2")
        
        let sut = makeSUT { data in
            #expect(data.eventName == target.eventName)
            #expect(data.id == target.id)
            NotificationCenter.default.post(name: target.notificationName, object: nil, userInfo: ["id": target.id])
        }
        
        let error = await #expect(throws: UnityBridgeAPIClientError.self, performing: {
            try await sut.request(target: target)
        })
        
        #expect(error == UnityBridgeAPIClientError.receivedInvalidData)
    }
    
    @Test("Test streaming  data then received the valid data", arguments: [
        [
            "id": "TEST_REQUEST_DATA_3",
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
    func testUnityBridgeAPIClient_whenStreamData_thenShouldReceivedExpectedResponse(userInfo: [String: String]?) async {
        
        // Given:
        let target = MockUnityTarget(id: "TEST_REQUEST_DATA_3")
        let sut = makeSUT { _ in }
        
        // When:
        await confirmation(#function) { expected in
            sut.stream(onEventName: target.eventName)
                .sink { data in
                    let decodedResponse: TestModel? = try? self.decoder.decode(key: .data, data: data)
                    #expect(decodedResponse == TestModel(title: "tests_structure", value: 100))
                    expected()
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.post(name: .init(target.eventName), object: nil, userInfo: userInfo)
        }
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
