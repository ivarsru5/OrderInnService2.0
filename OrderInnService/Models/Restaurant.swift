//
//  RestaruantLogin.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import Combine
import FirebaseFirestore

struct Restaurant: Identifiable, FirestoreInitiable {
    typealias ID = String

    static let firestoreCollection = "Restaurants"

    let id: ID
    let name: String
    let subscriptionPaid: Bool

    enum Key: String, CodingKey {
        case name = "name"
        case subscriptionPaid = "subscriptionPaid"
    }

    init(from snapshot: KeyedDocumentSnapshot<Restaurant>) {
        self.id = snapshot.documentID
        self.name = snapshot[.name] as! String
        self.subscriptionPaid = snapshot[.subscriptionPaid] as! Bool
    }

    #if DEBUG
    init(id: ID, name: String, subscriptionPaid: Bool) {
        self.id = id
        self.name = name
        self.subscriptionPaid = subscriptionPaid
    }
    #endif

    static func load(withID id: String) -> AnyPublisher<Restaurant, Error> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(id)
            .get()
    }

    var firestoreReference: TypedDocumentReference<Restaurant> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(id)
    }

    var users: TypedCollectionReference<Employee> {
        firestoreReference.collection(of: Employee.self)
    }
    var orders: TypedCollectionReference<RestaurantOrder> {
        firestoreReference.collection(of: RestaurantOrder.self)
    }

    @available(*, deprecated, message: "Call get() on .users instead")
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
        let fullName: String
        let isManager: Bool
        let isActive: Bool

        @available(*, deprecated, message: "Use firstName or fullName instead")
        var name: String { firstName }
        var firstName: String {
            var parts = fullName.split(separator: " ")
            _ = parts.popLast()
            return parts.joined(separator: " ")
        }
        var lastName: String {
            let parts = fullName.split(separator: " ")
            return String(parts.last!)
        }

        enum Key: String, CodingKey {
            case fullName = "fullName"
            case isActive = "isActive"
            case isManager = "isManager"

            case old_firstName = "name"
            case old_lastName = "lastName"
            case old_isManager = "manager"
        }

        init(from snapshot: KeyedDocumentSnapshot<Employee>) {
            self.id = snapshot.documentID

            if let fullName = snapshot[.fullName] as? String {
                self.fullName = fullName
            } else if let firstName = snapshot[.old_firstName] as? String,
                      let lastName = snapshot[.old_lastName] as? String {
                self.fullName = "\(firstName) \(lastName)"
            } else {
                fatalError("Unknown document format: Users/\(snapshot.documentID) has no valid name format")
            }

            self.isActive = snapshot[.isActive] as! Bool
            self.isManager = snapshot[.isManager, fallback: .old_isManager] as! Bool

            let restaurant = snapshot.reference.parentDocument(ofKind: Restaurant.self)
            self.restaurantID = restaurant.documentID
        }

        #if DEBUG
        @available(*, deprecated, message: "Use init(restaurantID: id: fullName: isManager: isActive:) instead")
        init(restaurantID: Restaurant.ID, id: ID, name: String, lastName: String,
             manager: Bool, isActive: Bool) {
            self.init(restaurantID: restaurantID, id: id,
                      fullName: "\(name) \(lastName)", isManager: manager,
                      isActive: isActive)
        }

        init(restaurantID: Restaurant.ID, id: ID, fullName: String,
             isManager: Bool, isActive: Bool) {
            self.restaurantID = restaurantID
            self.id = id
            self.fullName = fullName
            self.isManager = isManager
            self.isActive = isActive
        }
        #endif

        @available(*, deprecated, message: "Use init(under: fullName: isManager: isActive:) instead")
        static func create(under restaurant: Restaurant,
                           name: String, lastName: String, manager: Bool,
                           isActive: Bool = true) -> AnyPublisher<Employee, Error> {
            return self.create(under: restaurant, fullName: "\(name) \(lastName)",
                               isManager: manager, isActive: isActive)
        }

        static func create(under restaurant: Restaurant, fullName: String,
                           isManager: Bool, isActive: Bool = true) -> AnyPublisher<Employee, Error> {
            return restaurant.users
                .addDocumentAndCommit(data: [
                    .fullName: fullName,
                    .isManager: isManager,
                    .isActive: isActive,
                ])
                .flatMap { ref in ref.get() }
                .eraseToAnyPublisher()
        }

        var firestoreReference: TypedDocumentReference<Employee> {
            TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
                .document(restaurantID)
                .collection(of: Employee.self)
                .document(id)
        }

        func delete() -> AnyPublisher<Void, Error> {
            return firestoreReference.delete()
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

struct CurrentRestaurant: EnvironmentKey {
    static var defaultValue: Restaurant? = nil
}
struct CurrentEmployee: EnvironmentKey {
    static var defaultValue: Restaurant.Employee? = nil
}
extension EnvironmentValues {
    var currentRestaurant: Restaurant? {
        get { self[CurrentRestaurant.self] }
        set { self[CurrentRestaurant.self] = newValue }
    }
    var currentEmployee: Restaurant.Employee? {
        get { self[CurrentEmployee.self] }
        set { self[CurrentEmployee.self] = newValue }
    }
}
#endif
