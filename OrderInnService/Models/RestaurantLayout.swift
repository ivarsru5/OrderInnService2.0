//
//  RestaurantLayout.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Foundation
import FirebaseFirestore

struct Zone: FirestoreInitiable, Identifiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Pluralisation typo.
    static let firestoreCollection = "Zone"

    let restaurantID: Restaurant.ID
    let id: ID
    let location: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        location = snapshot["location"] as! String

        let restaurant = snapshot.reference.parent.parent!
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, location: String, restaurantID: Restaurant.ID) {
        self.id = id
        self.location = location
        self.restaurantID = restaurantID
    }
    #endif

    var firestoreReference: TypedDocumentReference<Zone> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }
}

struct Table: FirestoreInitiable, Identifiable {
    typealias ID = String

    struct FullID: Hashable, Equatable {
        let zone: Zone.ID
        let table: ID

        var string: String { "\(zone)/\(table)" }
    }

    static let firestoreCollection = "Tables"

    let restaurantID: Restaurant.ID
    let zoneID: Zone.ID
    let id: ID
    let name: String

    init(from snapshot: DocumentSnapshot) {
        precondition(snapshot.exists)
        id = snapshot.documentID
        if let name = snapshot["name"] as? String {
            self.name = name
        } else if let name = snapshot["table"] as? String {
            // TODO[pn 2021-07-16]: Remove old key name once it's no longer
            // present on any documents in Firestore.
            self.name = name
        } else {
            fatalError("FIXME No valid isAvailable key name found for LayoutTable: \(snapshot.reference.path)")
        }

        let zone = snapshot.reference.parent.parent!
        zoneID = zone.documentID
        let restaurant = zone.parent.parent!
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, name: String, restaurantID: Restaurant.ID, zoneID: Zone.ID) {
        self.id = id
        self.name = name
        self.restaurantID = restaurantID
        self.zoneID = zoneID
    }
    #endif

    var fullID: FullID {
        FullID(zone: zoneID, table: id)
    }

    var firestoreReference: TypedDocumentReference<Table> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(zoneID)
            .collection(Table.firestoreCollection)
            .document(id)
        return TypedDocumentReference(ref)
    }

    var zoneReference: TypedDocumentReference<Zone> {
        let ref = Firestore.firestore()
            .collection(Restaurant.firestoreCollection)
            .document(restaurantID)
            .collection(Zone.firestoreCollection)
            .document(zoneID)
        return TypedDocumentReference(ref)
    }
}

struct Layout {
    var zones: [Zone.ID: Zone]
    var tables: [Table.FullID: Table]

    init() {
        self.zones = [:]
        self.tables = [:]
    }

    init(zones: [Zone.ID: Zone], tables: [Table.FullID: Table]) {
        self.zones = zones
        self.tables = tables
    }

    #if DEBUG
    init(autoZones: [Zone], autoTables: [Table]) {
        self.zones = Dictionary(minimumCapacity: autoZones.count)
        self.tables = Dictionary(minimumCapacity: autoTables.count)
        autoZones.forEach { zone in
            zones[zone.id] = zone
        }
        autoTables.forEach { table in
            tables[table.fullID] = table
        }
    }
    #endif

    var orderedZones: [Zone] {
        return Array(zones.values).sorted(by: \.location)
    }
    func orderedTables(in zone: Zone) -> [Table] {
        let tables = Array(tables.values.filter({ $0.zoneID == zone.id }))
        return tables.sorted(by: \.name)
    }
}

#if canImport(SwiftUI)
import SwiftUI
struct CurrentLayout: EnvironmentKey {
    static var defaultValue = Binding<Layout>.constant(Layout())
}
extension EnvironmentValues {
    var currentLayout: Binding<Layout> {
        get { self[CurrentLayout.self] }
        set { self[CurrentLayout.self] = newValue }
    }
}

#if canImport(Combine)
import Combine

struct RestaurantLayoutLoader<Content: View>: View {
    let restaurant: Restaurant
    let content: () -> Content

    init(restaurant: Restaurant, @ViewBuilder content: @escaping () -> Content) {
        self.restaurant = restaurant
        self.content = content
    }

    @State var layout = Layout()
    @State var hasLayoutData = false

    var body: some View {
        Group {
            if hasLayoutData {
                content()
            } else {
                Spinner()
            }
        }
        .environment(\.currentLayout, $layout)
        .onAppear {
            if !hasLayoutData {
                loadLayoutData()
            }
        }
    }

    func loadLayoutData() {
        var sub: AnyCancellable?
        sub = restaurant.firestoreReference
            .collection(of: Zone.self)
            .get()
            .flatMap { zone -> AnyPublisher<Table, Error> in
                layout.zones[zone.id] = zone
                return zone.firestoreReference
                    .collection(of: Table.self)
                    .get()
            }
            .map { table in
                layout.tables[table.fullID] = table
            }
            .mapError { error in
                // TODO[pn 2021-08-05]: Should probably expose this to
                // downstream? Or have an alternate ErrorContent?
                fatalError("FIXME Failed to load layout in wrapper: \(String(describing: error))")
            }
            .ignoreOutput()
            .sink(receiveCompletion: { _ in
                hasLayoutData = true
                if let _ = sub {
                    sub = nil
                }
            })
    }
}
#endif // canImport(Combine)
#endif // canImport(SwiftUI)
