//
//  ActiveOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Combine
import FirebaseFirestore
import SwiftUI

struct ActiveOrderListView: View {
    class Model: ObservableObject {
        @Published var isLoading = true
        @Published var orders: [RestaurantOrder] = []
        @Published var zones: [Zone.ID: Zone] = [:]
        @Published var tables: [Table.ID: Table] = [:]
        @Published var menuCategories: [MenuCategory.ID: MenuCategory] = [:]
        @Published var menuItems: [MenuItem.FullID: MenuItem] = [:]

        var sub: AnyCancellable?
        private var orderQuery: TypedQuery<RestaurantOrder> {
            AuthManager.shared.restaurant.firestoreReference
                .collection(of: RestaurantOrder.self)
                .query
                .whereField("placedBy", isEqualTo: AuthManager.shared.waiter!.firestoreReference.untyped)
                .order(by: "createdAt", descending: true)
        }

        func subscribeToOrders() {
            print("[ActiveOrderList] Subscribing to order snapshots")

            sub = orderQuery.listen()
                .mapError { error in
                    // TODO[pn 2021-07-19]
                    fatalError("[ActiveOrderList] FIXME: Error while listening to orders: \(String(describing: error))")
                }
                .sink { [unowned self] orders in
                    if isLoading {
                        isLoading = false
                    }
                    print("[ActiveOrderList] Snapshot listener received \(orders.count) orders")
                    self.orders = orders
                    loadUnknownZonesAndTables()
                    loadUnknownItems()
                }
        }

        func unsubscribeFromOrders() {
            if let sub = self.sub {
                sub.cancel()
                self.sub = nil
            }
        }

        private func loadUnknownZonesAndTables() {
            var zones = Set<Zone.ID>()
            var tableZones: [Table.ID: Zone.ID] = [:]

            orders.forEach { order in
                let tableID = order.table.documentID
                let zoneID = order.table.parentDocument(ofKind: Zone.self).documentID

                if self.zones[zoneID] == nil {
                    zones.insert(zoneID)
                }
                if self.tables[tableID] == nil {
                    tableZones[tableID] = zoneID
                }
            }

            if zones.isEmpty && tableZones.isEmpty {
                return
            }
            print("[ActiveOrderList] Got requests for \(zones.count) zones and \(tableZones.count) tables")
            isLoading = true

            var sub: AnyCancellable?
            sub = AuthManager.shared.restaurant.firestoreReference
                .collection(of: Zone.self)
                .query
                .whereField(.documentID(), in: Array(zones))
                .get()
                .flatMap { [unowned self] zone -> AnyPublisher<Table, Error> in
                    self.zones[zone.id] = zone
                    let requiredTables = tableZones.filter { $0.1 == zone.id }.map { $0.0 }
                    return zone.firestoreReference
                        .collection(of: Table.self)
                        .query
                        .whereField(.documentID(), in: Array(requiredTables))
                        .get()
                }
                .mapError { error in
                    // TODO[pn 2021-07-19]
                    fatalError("[ActiveOrderList] BUG Error while fetching zones and/or tables: \(String(describing: error))")
                }
                .sink(receiveCompletion: { [unowned self] _ in
                    self.isLoading = false
                    if let _ = sub {
                        sub = nil
                    }
                }, receiveValue: { [unowned self] table in
                    self.tables[table.id] = table
                })
        }

        private func loadUnknownItems() {
            var items = Set<MenuItem.FullID>()

            orders.forEach { order in
                order.parts.indices.forEach { partIndex in
                    let part = order.parts[partIndex]
                    part.entries.indices.forEach { entryIndex in
                        let entry = part.entries[entryIndex]
                        guard menuItems[entry.itemID] == nil else { return }
                        items.insert(entry.itemID)
                    }
                }
            }
            if items.isEmpty {
                return
            }

            var categories = Set<MenuCategory.ID>()
            items.forEach { id in
                categories.insert(id.category)
            }

            var sub: AnyCancellable?
            sub = AuthManager.shared.restaurant.firestoreReference
                .collection(of: MenuCategory.self)
                .query
                .whereField(.documentID(), in: Array(categories))
                .get()
                .flatMap { [unowned self] category -> AnyPublisher<MenuItem, Error> in
                    self.menuCategories[category.id] = category
                    let relatedItems = items.filter { $0.category == category.id }.map { $0.item }
                    return category.firestoreReference
                        .collection(of: MenuItem.self)
                        .query
                        .whereField(.documentID(), in: Array(relatedItems))
                        .get()
                }
                .mapError { error in
                    // TODO[pn 2021-07-29]
                    fatalError("[ActiveOrderListView] BUG Failed to fetch menu: \(String(describing: error))")
                }
                .sink { item in
                    self.menuItems[item.fullID] = item
                    if let _ = sub {
                        sub = nil
                    }
                }
        }
    }

    @StateObject var model = Model()

    struct Cell: View {
        let order: RestaurantOrder
        let zone: Zone
        let table: Table

        @Binding var menuItems: [MenuItem.FullID: MenuItem]

        @State var shouldOpenNavigationLink = false
        var isMenuReady: Bool {
            !order.parts.contains(where: { part in
                part.entries.contains(where: { entry in
                    menuItems[entry.itemID] == nil
                })
            })
        }

        @ViewBuilder private var destination: some View {
            if isMenuReady {
                ActiveOrderDetailView(order: order, zone: zone, table: table,
                                      menu: $menuItems)
            } else {
                Spinner()
            }
        }

        var body: some View {
            NavigationLink(destination: destination) {
                HStack {
                    Text("Zone: ").bold() + Text(verbatim: zone.location)
                    Spacer()
                    Text("Table: ").bold() + Text(verbatim: table.name)
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if model.isLoading {
                Spinner()
            } else {
                Group {
                    if model.orders.isEmpty {
                        Text("There are currently no active orders.")
                            .font(.headline)
                            .foregroundColor(.label)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        List {
                            ForEach(model.orders) { order in
                                Cell(order: order,
                                     zone: model.zones[model.tables[order.table.documentID]!.zoneID]!,
                                     table: model.tables[order.table.documentID]!,
                                     menuItems: $model.menuItems)
                            }
                        }
                    }
                }
                .navigationTitle("Active Orders")
            }
        }
        .onAppear {
            if model.isLoading {
                model.subscribeToOrders()
            }
        }
        .onDisappear {
            if let sub = model.sub {
                sub.cancel()
                model.sub = nil
            }
        }
    }

    static var navigationViewWithTabItem: some View {
        NavigationView {
            ActiveOrderListView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tabItem {
            Image(systemName: "scroll")
            Text("Active Orders")
        }
    }
}

#if DEBUG
struct ActiveOrderView_Previews: PreviewProvider {
    static let model = ActiveOrderListView.Model()
    static func prepareModel() {
        model.isLoading = false
        model.zones = [
            "Z": Zone(id: "Z", location: "Test Zone", restaurantID: "R"),
        ]
        model.tables = [
            "T": Table(id: "T", name: "Test Table", restaurantID: "R", zoneID: "Z"),
        ]
    }

    struct Wrapper: View {
        let model: ActiveOrderListView.Model
        @State var nextOrderID = 1

        var body: some View {
            NavigationView {
                VStack {
                    ActiveOrderListView(model: model)

                    Button(action: {
                        let order = RestaurantOrder(restaurantID: "R", id: "O.\(nextOrderID)",
                                                    state: .open, table: "T",
                                                    placedBy: "U", createdAt: Date(),
                                                    parts: [])
                        model.orders.append(order)
                        nextOrderID += 1
                    }, label: {
                        Text("(DEBUG) Create New Order")
                    })
                }
            }
        }
    }

    static var previews: some View {
        let _ = prepareModel()

        Wrapper(model: model)
    }
}
#endif
