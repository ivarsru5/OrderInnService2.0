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

    func loadUsers() -> AnyPublisher<[Employee], Error> {
        return firestoreReference
            .collection(Employee.firestoreCollection, of: Employee.self)
            .get()
            .collect()
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

        static func load(forRestaurantID restaurantID: Restaurant.ID,
                         withUserID userID: Employee.ID) -> AnyPublisher<Employee, Error> {
            return Firestore.firestore()
                .collection("Restaurants")
                .document(restaurantID)
                .collection("Users")
                .document(userID)
                .getDocumentFuture()
                .map { snapshot in Employee(from: snapshot) }
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
    }
}
