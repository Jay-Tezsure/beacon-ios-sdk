//
//  CommunicationClient.swift
//  BeaconSDK
//
//  Created by Julia Samol on 16.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Transport.P2P {
    
    class CommunicationClient {
        private let appName: String
        private let appIcon: String?
        private let appURL: String?
        private let communicationUtils: CommunicationUtils
        private let serverUtils: ServerUtils
        private let matrixClients: [Matrix]
        private let crypto: Crypto
        private let keyPair: KeyPair
        private let timeUtils: TimeUtilsProtocol
        
        private var eventListeners: [HexString: Matrix.EventListener] = [:]
        private var serverSessionKeyPair: [HexString: SessionKeyPair] = [:]
        private var clientSessionKeyPair: [HexString: SessionKeyPair] = [:]
        
        init(
            appName: String,
            appIcon: String?,
            appURL: String?,
            communicationUtils: CommunicationUtils,
            serverUtils: ServerUtils,
            matrixClients: [Matrix],
            crypto: Crypto,
            keyPair: KeyPair,
            timeUtils: TimeUtilsProtocol
        ) {
            self.appName = appName
            self.appIcon = appIcon
            self.appURL = appURL
            self.communicationUtils = communicationUtils
            self.serverUtils = serverUtils
            self.matrixClients = matrixClients
            self.crypto = crypto
            self.keyPair = keyPair
            self.timeUtils = timeUtils
        }
        
        func start(completion: @escaping (Result<(), Swift.Error>) -> ()) {
            do {
                let loginDigest = try crypto.hash(message: "login:\(timeUtils.currentTimeMillis / 1000 / (5 * 60))", size: 32)
                let signature = HexString(from: try crypto.signDetached(message: loginDigest, with: keyPair.secretKey)).asString()
                let publicKeyHex = HexString(from: keyPair.publicKey).asString()
                let id = HexString(from: try crypto.hash(key: keyPair.publicKey)).asString()
                
                let password = "ed:\(signature):\(publicKeyHex)"
                let deviceID = publicKeyHex
                
                matrixClients.forEachAsync(body: { $0.start(userID: id, password: password, deviceID: deviceID, completion: $1) }) { results in
                    guard results.contains(where: { $0.isSuccess }) else {
                        completion(.failure(Error.startFailed(causedBy: results.compactMap { $0.error })))
                        return
                    }
                    
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        // MARK: Incoming Messages
        
        func listen(to publicKey: HexString, listener: @escaping (Result<String, Swift.Error>) -> ()) {
            guard eventListeners[publicKey] == nil else { return }

            let textMessageListener = Matrix.EventListener { [weak self] event in
                guard let selfStrong = self else { return }
                guard let textMessage = selfStrong.textMessage(from: event, sender: publicKey) else { return }
                
                listener(catchResult { try selfStrong.decrypt(message: textMessage, with: publicKey) })
            }
            
            eventListeners[publicKey] = textMessageListener
            matrixClients.forEach { $0.subscribe(for: .textMessage, with: textMessageListener) }
        }
        
        func removeListener(for publicKey: HexString) {
            guard let listener = eventListeners.removeValue(forKey: publicKey) else { return }
            matrixClients.forEach { $0.unsubscribe(listener) }
        }
        
        private func textMessage(from event: Matrix.Event, sender publicKey: HexString) -> Matrix.Event.TextMessage? {
            switch event {
            case let .textMessage(message):
                guard communicationUtils.isMessage(message, from: publicKey) && crypto.validate(encrypted: message.message) else {
                    return nil
                }
                
                return message
            default:
                return nil
            }
        }
        
        private func decrypt(message encrypted: Matrix.Event.TextMessage, with publicKey: HexString) throws -> String {
            let keyPair = try getOrCreateServerSessionKeyPair(for: publicKey)
            
            let decrypted: [UInt8] = try {
                if encrypted.message.isHex {
                    return try crypto.decrypt(message: try HexString(from: encrypted.message), withSharedKey: keyPair.rx)
                } else {
                    return try crypto.decrypt(message: encrypted.message, withSharedKey: keyPair.rx)
                }
            }()
                
            return String(bytes: decrypted, encoding: .utf8) ?? ""
        }
        
        private func getOrCreateServerSessionKeyPair(for publicKey: HexString) throws -> SessionKeyPair {
            try serverSessionKeyPair.getOrSet(publicKey) {
                try crypto.serverSessionKeyPair(publicKey: publicKey.asBytes(), secretKey: keyPair.secretKey)
            }
        }
        
        // MARK: Outgoing Messages
        
        func send(message: String, to peer: Beacon.P2PPeer, completion: @escaping (Result<(), Swift.Error>) -> ()) {
            do {
                let publicKey = try HexString(from: peer.publicKey)
                let recipient = try communicationUtils.recipientIdentifier(for: publicKey, on: peer.relayServer)
                let encrypted = HexString(from: try encrypt(message: message, with: publicKey)).asString()
                
                matrixClients.forEachAsync(body: { $0.send(textMessage: encrypted, to: recipient, completion: $1) }) { results in
                    guard results.contains(where: { $0.isSuccess }) else {
                        completion(.failure(Error.sendFailed(causedBy: results.compactMap { $0.error })))
                        return
                    }
                    
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        func sendPairingResponse(
            to peer: Beacon.P2PPeer,
            completion: @escaping (Result<(), Swift.Error>) -> ()
        ) {
            do {
                let publicKey = try HexString(from: peer.publicKey)
                let recipient = try communicationUtils.recipientIdentifier(for: publicKey, on: peer.relayServer)
                let pairingPayload = try communicationUtils.pairingPayload(
                    for: peer,
                    publicKey: keyPair.publicKey,
                    relayServer: try serverUtils.relayServer(for: keyPair.publicKey),
                    appName: appName,
                    appIcon: appIcon,
                    appURL: appURL
                )
                
                let payload = HexString(from: try crypto.encrypt(message: pairingPayload, withPublicKey: try publicKey.asBytes())).asString()
                let message = communicationUtils.channelOpeningMessage(to: recipient, withPayload: payload)
                
                matrixClients.forEachAsync(body: { $0.send(textMessage: message, to: recipient, completion: $1) }) { results in
                    guard results.contains(where: { $0.isSuccess }) else {
                        completion(.failure(Error.pairingFailed(causedBy: results.compactMap { $0.error })))
                        return
                    }
                    
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        private func encrypt(message: String, with publicKey: HexString) throws -> [UInt8] {
            let keyPair = try getOrCreateClientSessionKeyPair(for: publicKey)
            
            return try crypto.encrypt(message: message, withSharedKey: keyPair.tx)
        }
        
        private func getOrCreateClientSessionKeyPair(for publicKey: HexString) throws -> SessionKeyPair {
            try clientSessionKeyPair.getOrSet(publicKey) {
                try crypto.clientSessionKeyPair(publicKey: publicKey.asBytes(), secretKey: keyPair.secretKey)
            }
        }
        
        // MARK: Types
        
        enum Error: Swift.Error {
            case startFailed(causedBy: [Swift.Error])
            case sendFailed(causedBy: [Swift.Error])
            case pairingFailed(causedBy: [Swift.Error])
        }
    }
}

// MARK: Extensions

private extension Matrix {
    
    func send(textMessage message: String, to recipient: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        getRelevantRoom(withMember: recipient) { result in
            guard let roomOrNil = result.get(ifFailure: completion) else { return }
            
            guard let room = roomOrNil else {
                completion(.failure(Error.relevantRoomNotFound))
                return
            }
            
            self.send(message: message, to: room, completion: completion)
        }
    }
    
    func getRelevantRoom(withMember member: String, completion: @escaping (Result<Matrix.Room?, Swift.Error>) -> ()) {
        joinedRooms {
            guard let joined = $0.get(ifFailure: completion) else { return }
            if let room = joined.first(where: { $0.members.contains(member) }) {
                completion(.success(room))
            } else {
                self.createTrustedPrivateRoom(invitedMembers: [member]) { roomResult in
                    guard let roomOrNil = roomResult.get(ifFailure: completion) else { return }
                    guard let room = roomOrNil else {
                        completion(.success(nil))
                        return
                    }
                    
                    self.waitForMember(member, joining: room) { waitResult in
                        guard waitResult.get(ifFailure: completion) != nil else { return }
                        completion(.success(room))
                    }
                }
            }
        }
    }
    
    func waitForMember(_ member: String, joining room: Room, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        if room.members.contains(member) {
            completion(.success(()))
            return
        }
    
        var joinEventListener: EventListener!
        joinEventListener = EventListener { [weak self] event in
            switch event {
            case let .join(join):
                if join.roomID == room.id && join.userID == member {
                    self?.unsubscribe(joinEventListener)
                    completion(.success(()))
                }
            default:
                break
            }
            
        }
        subscribe(for: .join, with: joinEventListener)
    }
}
