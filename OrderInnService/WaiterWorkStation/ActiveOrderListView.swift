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
    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.currentLayout) @Binding var layout: Layout

    var body: some View {
        Group {
            if !orderManager.hasData {
                Spinner()
            } else if orderManager.orders.isEmpty {
                Text("There are currently no active orders.")
                    .font(.headline)
                    .foregroundColor(.label)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(orderManager.orders) { order in
                        let table = layout.tables[order.tableFullID]!
                        let zone = layout.zones[table.zoneID]!
                        NavigationLink(destination: ActiveOrderDetailView(order: order, zone: zone, table: table)) {
                            OrderListCell(order: order, zone: zone, table: table)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Active Orders")
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
    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)

    static var layout = Layout(zones: [
        "Z": Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id),
    ], tables: [
        Table.FullID(zone: "Z", table: "T"):
            Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z"),
    ])

    static var orderManager = OrderManager(debugForRestaurant: restaurant, withOrders: [
        RestaurantOrder(restaurantID: "R", id: "O1", state: .new,
                        table: Table.FullID(zone: "Z", table: "T"),
                        placedBy: "U", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: "R", id: "O2", state: .open,
                        table: Table.FullID(zone: "Z", table: "T"),
                        placedBy: "U", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: "R", id: "O3", state: .fulfilled,
                        table: Table.FullID(zone: "Z", table: "T"),
                        placedBy: "U", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: "R", id: "O4", state: .cancelled,
                        table: Table.FullID(zone: "Z", table: "T"),
                        placedBy: "U", createdAt: Date(), parts: []),
    ])

    static var previews: some View {
        NavigationView {
            ActiveOrderListView()
                .environment(\.currentRestaurant, restaurant)
                .environment(\.currentLayout, .constant(layout))
                .environmentObject(orderManager)
        }
    }
}
#endif
