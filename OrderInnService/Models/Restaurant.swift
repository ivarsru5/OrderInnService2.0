//
//  RestaruantLogin.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct Restaurant: Identifiable, FirestoreInitiable {
    typealias ID = String

    static let firestoreCollection = "Restaurants"

    let id: ID
    let name: String
    let subscriptionPaid: Bool

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        self.id = snapshot.documentID
        self.name = snapshot["name"] as! String
        self.subscriptionPaid = snapshot["subscriptionPaid"] as! Bool
    }

    #if DEBUG
    init(id: ID, name: String, subscriptionPaid: Bool) {
        self.id = id
        self.name = name
        self.subscriptionPaid = subscriptionPaid
    }
    #endif

    static func load(withID id: String) -> AnyPublisher<Restaurant, Error> {
        return Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(id)
            .getDocumentFuture()
            .map { snapshot in
                return Restaurant(from: snapshot)
            }
            .eraseToAnyPublisher()
    }

    var firestoreReference: TypedDocumentReference<Restaurant> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    var users: TypedCollectionReference<Employee> {
        firestoreReference.collection(Employee.firestoreCollection, of: Employee.self)
    }
    var orders: TypedCollectionReference<RestaurantOrder> {
        firestoreReference.collection(of: RestaurantOrder.self)
    }

    func loadUsers() -> AnyPublisher<[Employee], Error> {
        return users
            .get()
            .collect()
            .map { users in users.sorted(by: \.fullName) }
            .eraseToAnyPublisher()
    }

    struct Employee: Identifiable, FirestoreInitiable {
        typealias ID = String

        static let firestoreCollection = "Users"

        let restaurantID: Restaurant.ID
        let id: ID
        // TODO[pn 2021-07-09]: Is there a reason we're storing first and last
        // names separately and they instead couldn't be stored in a single
        // field?
        let name: String
        let lastName: String
        let manager: Bool
        let isActive: Bool

        var fullName: String {
            "\(name) \(lastName)"
        }

        init(from snapshot: DocumentSnapshot) {
            precondition(snapshot.exists)
            self.id = snapshot.documentID
            self.name = snapshot["name"] as! String
            self.lastName = snapshot["lastName"] as! String
            self.isActive = snapshot["isActive"] as! Bool
            self.manager = snapshot["manager"] as! Bool

            let restaurant = snapshot.reference.parent.parent!
            self.restaurantID = restaurant.documentID
        }

        #if DEBUG
        init(restaurantID: Restaurant.ID, id: ID, name: String, lastName: String,
             manager: Bool, isActive: Bool) {
            self.restaurantID = restaurantID
            self.id = id
            self.name = name
            self.lastName = lastName
            self.manager = manager
            self.isActive = isActive
        }
        #endif

        static func create(under restaurant: Restaurant,
                           name: String, lastName: String, manager: Bool,
                           isActive: Bool = true) -> AnyPublisher<Employee, Error> {
            return restaurant.users
                .addDocumentAndCommit(data: [
                    "name": name,
                    "lastName": lastName,
                    "manager": manager,
                    "isActive": isActive,
                ])
                .flatMap { ref in ref.get() }
                .eraseToAnyPublisher()
        }

        var firestoreReference: TypedDocumentReference<Employee> {
            let ref = Firestore.firestore()
                .collection(Restaurant.firestoreCollection)
                .document(restaurantID)
                .collection(Employee.firestoreCollection)
                .document(id)
            return TypedDocumentReference(ref)
        }

        func delete() -> AnyPublisher<Void, Error> {
            return firestoreReference.delete()
        }
    }
}
