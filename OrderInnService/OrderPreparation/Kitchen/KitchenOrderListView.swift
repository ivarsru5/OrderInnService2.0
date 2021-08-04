//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import Combine
import SwiftUI

struct KitchenOrderListView: View {
    struct Cell: View {
        let zone: Zone
        let table: Table
        let order: RestaurantOrder

        var statusIconColor: Color {
            switch order.state {
            case .new: return Color.blue
            case .open: return Color.label
            case .closed: return Color.secondary
            }
        }

        var body: some View {
            let destination = KitchenOrderDetailView(order: order, zone: zone, table: table)
            NavigationLink(destination: destination) {
                HStack {
                    Image(systemName: "circle.fill")
                        .symbolSize(10)
                        .foregroundColor(statusIconColor)
                    Text("Zone: ").bold() + Text(zone.location)
                    Spacer()
                    Text("Table: ").bold() + Text(table.name)
                }
                .foregroundColor(.label)
            }
        }
    }

    class Model: ObservableObject {
        @Published var hasData = false
        @Published var zones: [Zone.ID: Zone] = [:]
        @Published var tables: [Table.FullID: Table] = [:]

        func loadLayout(for restaurant: Restaurant) {
            var sub: AnyCancellable?
            sub = restaurant.firestoreReference
                .collection(of: Zone.self)
                .get()
                .flatMap { [unowned self] zone -> AnyPublisher<Table, Error> in
                    self.zones[zone.id] = zone
                    return zone.firestoreReference
                        .collection(of: Table.self)
                        .get()
                }
                .mapError { error in
                    // TODO[pn 2021-08-04]
                    fatalError("FIXME Failed to load restaurant layout for kitchen: \(String(describing: error))")
                }
                .map { [unowned self] table in
                    self.tables[table.fullID] = table
                }
                .ignoreOutput()
                .sink(receiveCompletion: { [unowned self] _ in
                    self.hasData = true
                    if let _ = sub {
                        sub = nil
                    }
                })
        }
    }

    @Environment(\.currentRestaurant) var restaurant: Restaurant?
    @EnvironmentObject var menuManager: MenuManager
    @EnvironmentObject var orderManager: OrderManager
    @StateObject var model = Model()

    var body: some View {
        Group {
            if !orderManager.hasData || !model.hasData {
                Spinner()
            } else {
                List {
                    ForEach(orderManager.orders) { order in
                        let table = model.tables[order.tableFullID]!
                        let zone = model.zones[table.zoneID]!
                        Cell(zone: zone, table: table, order: order)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Received Orders")
        .onAppear {
            if !model.hasData {
                model.loadLayout(for: restaurant!)
            }
        }
    }
}

#if DEBUG
struct KitchenOrderListView_Previews: PreviewProvider {
    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let menuManager = MenuManager(debugForRestaurant: restaurant, withMenu: [:], categories: [:])
    static let orderManager = OrderManager(debugForRestaurant: restaurant, withOrders: [
        RestaurantOrder(restaurantID: restaurant.id, id: "O1", state: .new,
                        table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                        createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O2", state: .open,
                        table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                        createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O3", state: .closed,
                        table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                        createdAt: Date(), parts: []),
    ])
    static var model: KitchenOrderListView.Model {
        let model = KitchenOrderListView.Model()
        model.zones = [
            "Z": Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id),
        ]
        model.tables = [
            Table.FullID(zone: "Z", table: "T"):
                Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z"),
        ]
        model.hasData = true
        return model
    }

    static var previews: some View {
        KitchenOrderListView(model: model)
            .environment(\.currentRestaurant, restaurant)
            .environmentObject(menuManager)
            .environmentObject(orderManager)
    }
}
#endif
