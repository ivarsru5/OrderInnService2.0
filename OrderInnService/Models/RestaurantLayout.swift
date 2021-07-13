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

    private let restaurantID: Restaurant.ID
    let id: ID
    let location: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        location = snapshot["location"] as! String

        let restaurant = snapshot.reference.parent.parent!
        restaurantID = restaurant.documentID
    }

    var firebaseReference: TypedDocumentReference<Zone> {
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

    static let firestoreCollection = "Tables"

    private let restaurantID: Restaurant.ID
    private let zoneID: Zone.ID
    let id: ID
    let name: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        name = snapshot["name"] as! String

        let zone = snapshot.reference.parent.parent!
        zoneID = zone.documentID
        let restaurant = zone.parent.parent!
        restaurantID = restaurant.documentID
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
}
