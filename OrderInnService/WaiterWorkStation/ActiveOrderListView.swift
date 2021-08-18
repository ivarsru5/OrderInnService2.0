//
//  ActiveOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Combine
import SwiftUI

struct ActiveOrderListView: View {
    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.currentLayout) @Binding var layout: Layout
    @Environment(\.currentEmployee) var employee: Restaurant.Employee?

    var orders: [RestaurantOrder] {
        get {
            // In manager mode, the OrderManager adds a subscription to all
            // orders, including those from other waiters. This tab only lists
            // the orders placed by the current user, whereas others are
            // displayed within the manager controls section.
            var orders = orderManager.orders
            if let employee = self.employee, employee.isManager {
                orders = orders.filter({ $0.placedBy == employee.firestoreReference })
            }
            return orders
        }
    }
    var body: some View {
        Group {
            if !orderManager.hasData {
                Spinner()
            } else if orders.isEmpty {
                Text("There are currently no active orders.")
                    .foregroundColor(.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(orders) { order in
                        NavigationLink(destination: ActiveOrderDetailView(order: order)) {
                            OrderListCell(order: order)
                        }
                    }
                }
                .animation(.default, value: orders.count)
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationBarTitle("Active Orders")
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
