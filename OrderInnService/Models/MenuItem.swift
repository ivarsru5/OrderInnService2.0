//
//  MenuItem.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Combine
import Foundation
import FirebaseFirestore

struct MenuItem: Identifiable, Hashable, FirestoreInitiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Nondescript name.
    static let firestoreCollection = "Menu"

    enum Destination: String, Codable {
        case kitchen = "kitchen"
        case bar = "bar"

        init(from string: String) throws {
            switch string {
            case Destination.kitchen.rawValue: self = .kitchen
            case Destination.bar.rawValue: self = .bar
            default: throw ModelError.invalidEnumStringEncoding
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            try self.init(from: value)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }

    private let restaurantID: Restaurant.ID
    private let categoryID: MenuCategory.ID
    let id: ID
    let name: String
    let price: Double
    let isAvailable: Bool
    let destination: Destination

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        name = snapshot["name"] as! String
        price = snapshot["price"] as! Double
        isAvailable = snapshot["isAvailable"] as! Bool
        destination = try! Destination(from: snapshot["destination"] as! String)

        let category = snapshot.reference.parent.parent!
        categoryID = category.documentID
        let restaurant = category.parent.parent!
        restaurantID = restaurant.documentID
    }

    var firestoreReference: TypedDocumentReference<MenuItem> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(MenuCategory.firestoreCollection)
            .document(categoryID)
            .collection(MenuItem.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    static func create(in category: MenuCategory,
                       name: String, price: Double, destination: Destination,
                       isAvailable: Bool = true) -> AnyPublisher<MenuItem, Error> {
        category.firestoreReference
            .collection(self.firestoreCollection, of: MenuItem.self)
            .addDocument(data: [
                "name": name,
                "price": price,
                "isAvailable": isAvailable,
                "destination": destination.rawValue,
            ])
            .get()
    }
}
