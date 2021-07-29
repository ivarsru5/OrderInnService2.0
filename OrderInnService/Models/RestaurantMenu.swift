//
//  RestaurantMenu.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Combine
import Foundation
import FirebaseFirestore

struct MenuCategory: Identifiable, Hashable, FirestoreInitiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Pluralisation typo.
    static let firestoreCollection = "MenuCategory"

    enum CategoryType: String, Equatable, Codable {
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

    let restaurantID: Restaurant.ID
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

    #if DEBUG
    init(id: ID, name: String, type: CategoryType, restaurantID: Restaurant.ID) {
        self.id = id
        self.name = name
        self.type = type
        self.restaurantID = restaurantID
    }
    #endif

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

    struct FullID: Hashable, Equatable, Codable {
        let category: MenuCategory.ID
        let item: ID

        init(category: MenuCategory.ID, item: ID) {
            self.category = category
            self.item = item
        }
        init?(string: String) {
            guard let tuple = FullID.unparse(string: string) else { return nil }
            self.category = tuple.0
            self.item = tuple.1
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let tuple = FullID.unparse(string: string) else {
                throw ModelError.invalidFormat
            }
            self.category = tuple.0
            self.item = tuple.1
        }

        private static func unparse(string: String) -> (MenuCategory.ID, ID)? {
            let parts = string.split(separator: "/")
            guard parts.count == 2 else { return nil }
            let category = MenuCategory.ID(parts[0])
            let item = ID(parts[1])
            return (category, item)
        }

        var string: String { "\(category)/\(item)" }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.string)
        }
    }

    let restaurantID: Restaurant.ID
    let categoryID: MenuCategory.ID
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
        destination = try! Destination(from: snapshot["destination"] as! String)

        if let isAvailable = snapshot["isAvailable"] as? Bool {
            self.isAvailable = isAvailable
        } else if let isAvailable = snapshot["available"] as? Bool {
            // TODO[pn 2021-07-16]: Remove old key name once it's no longer
            // present on any documents in Firestore.
            self.isAvailable = isAvailable
        } else {
            fatalError("FIXME No valid isAvailable key name found for MenuItem: \(snapshot.reference.path)")
        }

        let category = snapshot.reference.parent.parent!
        categoryID = category.documentID
        let restaurant = category.parent.parent!
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, name: String, price: Double, isAvailable: Bool,
         destination: Destination, restaurantID: Restaurant.ID,
         categoryID: MenuCategory.ID) {
        self.id = id
        self.name = name
        self.price = price
        self.isAvailable = isAvailable
        self.destination = destination
        self.restaurantID = restaurantID
        self.categoryID = categoryID
    }
    #endif

    var fullID: FullID {
        return FullID(category: categoryID, item: id)
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