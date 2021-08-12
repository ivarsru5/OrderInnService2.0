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

    enum Key: String, CodingKey {
        case location = "location"
    }

    let restaurantID: Restaurant.ID
    let id: ID
    let location: String

    init(from snapshot: KeyedDocumentSnapshot<Zone>) {
        self.id = snapshot.documentID
        self.location = snapshot[.location] as! String

        let restaurant = snapshot.reference.parentDocument(ofKind: Restaurant.self)
        self.restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, location: String, restaurantID: Restaurant.ID) {
        self.id = id
        self.location = location
        self.restaurantID = restaurantID
    }
    #endif

    var firestoreReference: TypedDocumentReference<Zone> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(restaurantID)
            .collection(of: Zone.self)
            .document(id)
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

    enum Key: String, CodingKey {
        case name = "name"

        @available(*, deprecated)
        case old_name = "table"
    }

    let restaurantID: Restaurant.ID
    let zoneID: Zone.ID
    let id: ID
    let name: String

    init(from snapshot: KeyedDocumentSnapshot<Table>) {
        self.id = snapshot.documentID
        self.name = snapshot[.name, fallback: .old_name] as! String

        let zone = snapshot.reference.parentDocument(ofKind: Zone.self)
        self.zoneID = zone.documentID
        let restaurant = zone.parentDocument(ofKind: Restaurant.self)
        self.restaurantID = restaurant.documentID
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
        return zoneReference
            .collection(of: Table.self)
            .document(self.id)
    }

    var zoneReference: TypedDocumentReference<Zone> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(restaurantID)
            .collection(of: Zone.self)
            .document(zoneID)
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
