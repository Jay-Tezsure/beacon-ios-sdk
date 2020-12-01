//
//  OperationV2Response.swift
//  BeaconSDK
//
//  Created by Julia Samol on 13.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Beacon.Message.Versioned.V2 {
    
    struct OperationResponse: V2MessageProtocol, Codable {
        let type: `Type`
        let version: String
        let id: String
        let senderID: String
        let transactionHash: String
        
        init(version: String, id: String, senderID: String, transactionHash: String) {
            type = .operationResponse
            self.version = version
            self.id = id
            self.senderID = senderID
            self.transactionHash = transactionHash
        }
        
        // MARK: BeaconMessage Compatibility
        
        init(from beaconMessage: Beacon.Response.Operation, version: String, senderID: String) {
            self.init(version: version, id: beaconMessage.id, senderID: senderID, transactionHash: beaconMessage.transactionHash)
        }
        
        func comesFrom(_ appMetadata: Beacon.AppMetadata) -> Bool {
            appMetadata.senderID == senderID
        }
        
        func toBeaconMessage(
            with origin: Beacon.Origin,
            using storage: StorageManager,
            completion: @escaping (Result<Beacon.Message, Error>) -> ()
        ) {
            let message = Beacon.Message.response(
                Beacon.Response.operation(
                    Beacon.Response.Operation(id: id, transactionHash: transactionHash)
                )
            )
            
            completion(.success(message))
        }
        
        // MARK: Codable
        
        enum CodingKeys: String, CodingKey {
            case type
            case version
            case id
            case senderID = "senderId"
            case transactionHash
        }
    }
}