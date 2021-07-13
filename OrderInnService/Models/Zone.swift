//
//  Zones.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
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

    var firestoreReference: TypedDocumentReference<Zone> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }
}
