//
//  MenuCategory.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Combine
import Foundation
import FirebaseFirestore

struct MenuCategory: Identifiable, Hashable, FirestoreInitiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Pluralisation typo.
    static let firestoreCollection = "MenuCategory"

    enum CategoryType: String, Codable {
        case food = "food"
        case drink = "drink"

        init(from string: String) throws {
            switch string {
            case CategoryType.food.rawValue: self = .food
            case CategoryType.drink.rawValue: self = .drink
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
    let id: ID
    let name: String
    let type: CategoryType

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        name = snapshot["name"] as! String
        type = try! CategoryType(from: snapshot["type"] as! String)

        let restaurant = snapshot.reference.parent.parent!
        restaurantID = restaurant.documentID
    }

    var firestoreReference: TypedDocumentReference<MenuCategory> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(MenuCategory.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    static func create(under restaurant: Restaurant,
                       name: String, type: CategoryType) -> AnyPublisher<MenuCategory, Error> {
        restaurant.firestoreReference
            .collection(self.firestoreCollection, of: MenuCategory.self)
            .addDocument(data: [
                "name": name,
                "type": type.rawValue,
            ])
            .get()
    }
}
