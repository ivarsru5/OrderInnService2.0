//
//  KitchenOrder.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 22/05/2021.
//

import Combine
import Foundation
import FirebaseFirestore

struct KitchenOrder: Identifiable, FirestoreInitiable {
    typealias ID = String

    static let firestoreCollection = "Orders"

    enum OrderState: String, Codable {
        /// Order is submitted and hasn't been seen.
        case new = "new"

        /// Order is submitted and seen but hasn't been fulfilled or has been fulfilled partially.
        case `open` = "open"

        /// Order has been fully fulfilled.
        case closed = "closed"

        init(from string: String) throws {
            switch string {
            case OrderState.new.rawValue: self = .new
            case OrderState.open.rawValue: self = .open
            case OrderState.closed.rawValue: self = .closed
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
    struct OrderPart: Codable {
        let items: [OrderItem]
        var subtotal: Currency { items.map { item in item.subtotal }.sum() }

        init(items: [OrderItem]) {
            self.items = items
        }

        init(from decoder: Decoder) throws {
            items = try [OrderItem].self(from: decoder)
        }

        func encode(to encoder: Encoder) throws {
            try items.encode(to: encoder)
        }
    }
    struct OrderItem: Codable {
        let itemID: MenuItem.ID
        var item: MenuItem!
        let amount: Int
        var subtotal: Currency { item.price * amount }

        enum ItemCodingKey: String, CodingKey {
            case itemID = "id"
            case amount = "amt"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ItemCodingKey.self)
            try container.encode(item.id, forKey: .itemID)
            try container.encode(amount, forKey: .amount)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ItemCodingKey.self)
            itemID = try container.decode(MenuItem.ID.self, forKey: .itemID)
            amount = try container.decode(Int.self, forKey: .amount)
        }
    }

    private let restaurantID: Restaurant.ID
    let id: ID
    let state: OrderState
    let table: TypedDocumentReference<Table>
    let placedBy: TypedDocumentReference<Restaurant.Employee>
    let createdAt: Date
    let parts: [OrderPart]

    var isOpened: Bool { true } // [pn] ?
    var isSeen: Bool {
        switch state {
        case .new: return false
        default: return true
        }
    }
    var isReady: Bool {
        // TODO[pn 2021-07-13]: This is not meaningful if the order can be
        // fulfilled partially.
        return false
    }

    var total: Currency {
        parts.map { part in part.subtotal }.sum()
    }

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        restaurantID = snapshot.reference.parent.parent!.documentID
        id = snapshot.documentID
        state = try! OrderState(from: snapshot["state"] as! String)
        table = .init(snapshot["table"] as! DocumentReference)
        placedBy = .init(snapshot["placedBy"] as! DocumentReference)
        createdAt = ISO8601DateFormatter().date(from: snapshot["createdAt"] as! String)!

        let parts = snapshot["parts"] as! [Any]
        let json = JSONDecoder()
        self.parts = parts.map { anyPart in
            try! json.decode(OrderPart.self, from: anyPart as! Data)
        }
    }

    var firestoreReference: TypedDocumentReference<KitchenOrder> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(KitchenOrder.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    static func create(under restaurant: Restaurant,
                       placedBy user: Restaurant.Employee,
                       forTable table: Table,
                       withItems items: [OrderItem]) -> AnyPublisher<KitchenOrder, Error> {
        let part = OrderPart(items: items)
        let parts: [Any]

        do {
            parts = [try JSONEncoder().encode(part)]
        } catch {
            return Fail(outputType: KitchenOrder.self, failure: error).eraseToAnyPublisher()
        }

        return restaurant.firestoreReference
            .collection(self.firestoreCollection, of: KitchenOrder.self)
            .addDocument(data: [
                "state": OrderState.new.rawValue,
                "table": table.firestoreReference.untyped,
                "placedBy": user.firestoreReference.untyped,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "parts": parts,
            ])
            .get()
    }
}
