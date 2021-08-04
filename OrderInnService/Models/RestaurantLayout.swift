//
//  RestaurantLayout.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Foundation
import FirebaseFirestore

struct Zone: FirestoreInitiable, Identifiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Pluralisation typo.
    static let firestoreCollection = "Zone"

    let restaurantID: Restaurant.ID
    let id: ID
    let location: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        location = snapshot["location"] as! String

        let restaurant = snapshot.reference.parent.parent!
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, location: String, restaurantID: Restaurant.ID) {
        self.id = id
        self.location = location
        self.restaurantID = restaurantID
    }
    #endif

    var firestoreReference: TypedDocumentReference<Zone> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }
}

struct Table: FirestoreInitiable, Identifiable {
    typealias ID = String

    struct FullID: Hashable, Equatable {
        let zone: Zone.ID
        let table: ID
    }

    static let firestoreCollection = "Tables"

    let restaurantID: Restaurant.ID
    let zoneID: Zone.ID
    let id: ID
    let name: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        if let name = snapshot["name"] as? String {
            self.name = name
        } else if let name = snapshot["table"] as? String {
            // TODO[pn 2021-07-16]: Remove old key name once it's no longer
            // present on any documents in Firestore.
            self.name = name
        } else {
            fatalError("FIXME No valid isAvailable key name found for LayoutTable: \(snapshot.reference.path)")
        }

        let zone = snapshot.reference.parent.parent!
        zoneID = zone.documentID
        let restaurant = zone.parent.parent!
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, name: String, restaurantID: Restaurant.ID, zoneID: Zone.ID) {
        self.id = id
        self.name = name
        self.restaurantID = restaurantID
        self.zoneID = zoneID
    }
    #endif

    var fullID: FullID {
        FullID(zone: zoneID, table: id)
    }

    var firestoreReference: TypedDocumentReference<Table> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(zoneID)
            .collection(Table.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    var zoneReference: TypedDocumentReference<Zone> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(zoneID)
        return TypedDocumentReference(ref)
    }
}
