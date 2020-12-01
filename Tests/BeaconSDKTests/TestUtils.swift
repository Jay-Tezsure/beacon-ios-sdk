//
//  TestUtils.swift
//  BeaconSDKTests
//
//  Created by Julia Samol on 13.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation
@testable import BeaconSDK

// MARK: factories

func permissionBeaconRequest(
    id: String = "id",
    senderID: String = "senderID",
    appMetadata: Beacon.AppMetadata = Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
    network: Beacon.Network = Beacon.Network(type: .custom),
    scopes: [Beacon.PermissionScope] = [],
    origin: Beacon.Origin = .p2p(id: "senderID")
) -> Beacon.Request.Permission {
    Beacon.Request.Permission(
        id: id,
        senderID: senderID,
        appMetadata: appMetadata,
        network: network,
        scopes: scopes,
        origin: origin
    )
}

func operationBeaconRequest(
    id: String = "id",
    senderID: String = "senderID",
    appMetadata: Beacon.AppMetadata? = Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
    network: Beacon.Network = Beacon.Network(type: .custom),
    operationDetails: [Tezos.Operation] = [],
    sourceAddress: String = "sourceAddress",
    origin: Beacon.Origin = .p2p(id: "senderID")
) -> Beacon.Request.Operation {
    Beacon.Request.Operation(
        id: id,
        senderID: senderID,
        appMetadata: appMetadata,
        network: network,
        operationDetails: operationDetails,
        sourceAddress: sourceAddress,
        origin: origin
    )
}

func signPayloadBeaconRequest(
    id: String = "id",
    senderID: String = "senderID",
    appMetadata: Beacon.AppMetadata? = Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
    payload: String = "payload",
    sourceAddress: String = "sourceAddress",
    origin: Beacon.Origin = .p2p(id: "senderID")
) -> Beacon.Request.SignPayload {
    Beacon.Request.SignPayload(
        id: id,
        senderID: senderID,
        appMetadata: appMetadata,
        payload: payload,
        sourceAddress: sourceAddress,
        origin: origin
    )
}

func broadcastBeaconRequest(
    id: String = "id",
    senderID: String = "senderID",
    appMetadata: Beacon.AppMetadata? = Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
    network: Beacon.Network = Beacon.Network(type: .custom),
    signedTransaction: String = "signedTransaction",
    origin: Beacon.Origin = .p2p(id: "senderID")
) -> Beacon.Request.Broadcast {
    Beacon.Request.Broadcast(
        id: id,
        senderID: senderID,
        appMetadata: appMetadata,
        network: network,
        signedTransaction: signedTransaction,
        origin: origin
    )
}

func permissionBeaconResponse(
    id: String = "id",
    publicKey: String = "publicKey",
    network: Beacon.Network = Beacon.Network(type: .custom),
    scopes: [Beacon.PermissionScope] = []
) -> Beacon.Response.Permission {
    Beacon.Response.Permission(id: id, publicKey: id, network: network, scopes: scopes)
}

func operationBeaconResponse(
    id: String = "id",
    transactionHash: String = "transactionHash"
) -> Beacon.Response.Operation {
    Beacon.Response.Operation(id: id, transactionHash: transactionHash)
}

func signPayloadBeaconResponse(
    id: String = "id",
    signature: String = "signature"
) -> Beacon.Response.SignPayload {
    Beacon.Response.SignPayload(id: id, signature: signature)
}

func broadcastBeaconResponse(
    id: String = "id",
    transactionHash: String = "transactionHash"
) -> Beacon.Response.Broadcast {
    Beacon.Response.Broadcast(id: id, transactionHash: transactionHash)
}

func errorBeaconResponse(
    id: String = "id",
    type: Beacon.ErrorType = .unknown
) -> Beacon.Response.Error {
    Beacon.Response.Error(id: id, errorType: type)
}

func disconnectBeaconMessage(
    id: String = "id",
    senderID: String = "senderID"
) -> Beacon.Message.Disconnect {
    Beacon.Message.Disconnect(id: id, senderID: senderID)
}

func errorBeaconResponses(id: String = "id") -> [Beacon.Response.Error] {
    [
        errorBeaconResponse(id: id, type: .broadcastError),
        errorBeaconResponse(id: id, type: .networkNotSupported),
        errorBeaconResponse(id: id, type: .noAddressError),
        errorBeaconResponse(id: id, type: .noPrivateKeyFound),
        errorBeaconResponse(id: id, type: .notGranted),
        errorBeaconResponse(id: id, type: .parametersInvalid),
        errorBeaconResponse(id: id, type: .tooManyOperations),
        errorBeaconResponse(id: id, type: .transactionInvalid),
        errorBeaconResponse(id: id, type: .aborted),
        errorBeaconResponse(id: id, type: .unknown),
    ]
}

func beaconRequests(
    id: String = "id",
    senderID: String = "senderID",
    appMetadata: Beacon.AppMetadata = Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
    origin: Beacon.Origin = .p2p(id: "senderID")
) -> [Beacon.Request] {
    [
        .permission(permissionBeaconRequest(id: id, senderID: senderID, appMetadata: appMetadata, origin: origin)),
        .operation(operationBeaconRequest(id: id, senderID: senderID, appMetadata: appMetadata, origin: origin)),
        .signPayload(signPayloadBeaconRequest(id: id, senderID: senderID, appMetadata: appMetadata, origin: origin)),
        .broadcast(broadcastBeaconRequest(id: id, senderID: senderID, appMetadata: appMetadata, origin: origin)),
    ]
}

let beaconResponses: [Beacon.Response] = [
    .permission(permissionBeaconResponse()),
    .operation(operationBeaconResponse()),
    .signPayload(signPayloadBeaconResponse()),
    .broadcast(broadcastBeaconResponse()),
] + errorBeaconResponses().map { .error($0) }

func beaconVersionedRequests(
    version: String = "version",
    senderID: String = "senderID",
    requests: [Beacon.Request] = beaconRequests(
        senderID: "senderID",
        appMetadata: Beacon.AppMetadata(senderID: "senderID", name: "mockApp"),
        origin: .p2p(id: "senderID")
    )
) -> [Beacon.Message.Versioned] {
    requests.map { Beacon.Message.Versioned(from: .request($0), version: version, senderID: senderID) }
}