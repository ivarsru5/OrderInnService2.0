//
//  Tables.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Foundation
import FirebaseFirestore

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
