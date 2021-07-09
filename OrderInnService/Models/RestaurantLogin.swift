//
//  RestaruantLogin.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct Restaurant: Identifiable {
    typealias ID = String

    static let firebaseCollection = "Restaurants"

    let id: ID
    let name: String
    let subscriptionPaid: Bool

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        self.id = snapshot.documentID
        self.name = snapshot["name"] as! String
        self.subscriptionPaid = snapshot["subscriptionPaid"] as! Bool
    }

    static func load(withID id: String) -> Publishers.Map<Future<DocumentSnapshot, Error>, Restaurant> {
        return Firestore.firestore()
            .collection(Restaurant.firebaseCollection)
            .document(id)
            .getDocumentFuture()
            .map { snapshot in
                return Restaurant(from: snapshot)
            }
    }

    var firebaseReference: DocumentReference {
        Firestore.firestore()
            .collection(Restaurant.firebaseCollection)
            .document(id)
    }

    func loadUsers() -> Publishers.Map<Future<QuerySnapshot, Error>, [Employee]> {
        return Firestore.firestore()
            .collection(Restaurant.firebaseCollection)
            .document(id)
            .collection(Employee.firebaseCollection)
            .getDocumentsFuture()
            .map { snapshot in
                return snapshot.documents.map { document in
                    return Employee(from: document, withRestaurantID: id)
                }
            }
    }

    struct Employee: Identifiable {
        typealias ID = String

        static let firebaseCollection = "Users"

        let restaurantID: Restaurant.ID
        let id: ID
        // TODO[pn 2021-07-09]: Is there a reason we're storing first and last
        // names separately and they instead couldn't be stored in a single
        // field?
        let name: String
        let lastName: String
        let manager: Bool
        let isActive: Bool

        init(from snapshot: DocumentSnapshot, withRestaurantID restaurantID: Restaurant.ID) {
            precondition(snapshot.exists)
            self.restaurantID = restaurantID
            self.id = snapshot.documentID
            self.name = snapshot["name"] as! String
            self.lastName = snapshot["lastName"] as! String
            self.isActive = snapshot["isActive"] as! Bool
            self.manager = snapshot["manager"] as! Bool
        }

        static func load(forRestaurantID restaurantID: Restaurant.ID,
                         withUserID userID: Employee.ID) -> Future<Employee, Error> {
            return Future() { resolve in
                Firestore.firestore()
                    .collection("Restaurants")
                    .document(restaurantID)
                    .collection("Users")
                    .document(userID)
                    .getDocument {
                        maybeSnapshot, error in
                        guard let snapshot = maybeSnapshot else {
                            resolve(.failure(error!))
                            return
                        }

                        let employee = Employee(from: snapshot, withRestaurantID: restaurantID)
                        resolve(.success(employee))
                    }
            }
        }

        var firebaseReference: DocumentReference {
            Firestore.firestore()
                .collection(Restaurant.firebaseCollection)
                .document(restaurantID)
                .collection(Employee.firebaseCollection)
                .document(id)
        }
    }
}