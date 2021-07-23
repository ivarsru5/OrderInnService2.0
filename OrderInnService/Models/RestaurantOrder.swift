//
//  Order.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 22/04/2021.
//

import Combine
import Foundation
import FirebaseFirestore

struct RestaurantOrder: Identifiable, FirestoreInitiable {
    typealias ID = String

    static let firestoreCollection = "Orders"

    enum OrderState: String, Equatable, Codable {
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
        let entries: [OrderEntry]
        var subtotal: Currency { entries.map { $0.subtotal }.sum() }

        init(entries: [OrderEntry]) {
            self.entries = entries
        }

        init(from decoder: Decoder) throws {
            entries = try [OrderEntry](from: decoder)
        }

        func encode(to encoder: Encoder) throws {
            try entries.encode(to: encoder)
        }
    }
    struct OrderEntry: Codable {
        let itemID: MenuItem.FullID
        var item: MenuItem!
        let amount: Int
        var subtotal: Currency { item.price * amount }

        init(item: MenuItem, amount: Int) {
            self.itemID = item.fullID
            self.item = item
            self.amount = amount
        }

        func with(amount: Int) -> OrderEntry {
            return OrderEntry(item: item, amount: amount)
        }

        enum EntryCodingKey: String, CodingKey {
            case itemID = "id"
            case amount = "amt"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: EntryCodingKey.self)
            itemID = try container.decode(MenuItem.FullID.self, forKey: .itemID)
            amount = try container.decode(Int.self, forKey: .amount)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: EntryCodingKey.self)
            try container.encode(item.fullID, forKey: .itemID)
            try container.encode(amount, forKey: .amount)
        }
    }

    let restaurantID: Restaurant.ID
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
        id = snapshot.documentID
        state = try! OrderState(from: snapshot["state"] as! String)
        table = .init(snapshot["table"] as! DocumentReference)
        placedBy = .init(snapshot["placedBy"] as! DocumentReference)
        createdAt = ISO8601DateFormatter().date(from: snapshot["createdAt"] as! String)!

        let restaurant = snapshot.reference.parent.parent!
        restaurantID = restaurant.documentID

        let parts = snapshot["parts"] as! [Any]
        let json = JSONDecoder()
        self.parts = parts.map { part in
            // FIXME[pn 2021-07-20]: Normally every part should be a binary,
            // but since the Firestore Web UI doesn't support entering binary
            // data manually, until we have a CLI or some other way to submit
            // test orders, they're entered as strings instead.
            let partData: Data
            if let data = part as? Data {
                partData = data
            } else if let string = part as? String {
                partData = string.data(using: .ascii)!
            } else {
                fatalError("FIXME Unknown part format for order \(snapshot.documentID)")
            }

            return try! json.decode(OrderPart.self, from: partData)
        }
    }

    #if DEBUG
    init(restaurantID: Restaurant.ID, id: ID, state: OrderState, table: Table.ID,
         placedBy: Restaurant.Employee.ID, createdAt: Date, parts: [OrderPart]) {
        self.restaurantID = restaurantID
        self.id = id
        self.state = state
        self.table = TypedDocumentReference(nil, idOverride: table)
        self.placedBy = TypedDocumentReference(nil, idOverride: placedBy)
        self.createdAt = createdAt
        self.parts = parts
    }
    #endif

    static func create(under restaurant: Restaurant,
                       placedBy user: Restaurant.Employee,
                       forTable table: Table,
                       withEntries entries: [OrderEntry]) -> AnyPublisher<RestaurantOrder, Error> {
        let part = OrderPart(entries: entries)
        let parts: [Any]

        do {
            parts = [try JSONEncoder().encode(part)]
        } catch {
            return Fail(outputType: RestaurantOrder.self, failure: error).eraseToAnyPublisher()
        }

        return restaurant.firestoreReference
            .collection(self.firestoreCollection, of: RestaurantOrder.self)
            .addDocument(data: [
                "state": OrderState.new.rawValue,
                "table": table.firestoreReference.untyped,
                "placedBy": user.firestoreReference.untyped,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "parts": parts,
            ])
            .get()
    }

    var firestoreReference: TypedDocumentReference<RestaurantOrder> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(RestaurantOrder.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    func updateState(_ newState: OrderState) -> AnyPublisher<RestaurantOrder, Error> {
        return firestoreReference
            .updateData(["state": newState.rawValue])
            .flatMap { ref in ref.get() }
            .eraseToAnyPublisher()
    }
}
