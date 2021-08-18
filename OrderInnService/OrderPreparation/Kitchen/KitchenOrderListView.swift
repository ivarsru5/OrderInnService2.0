//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import Combine
import SwiftUI

struct KitchenOrderListView: View {
    @Environment(\.currentRestaurant) var restaurant: Restaurant?
    @Environment(\.currentLayout) @Binding var layout: Layout
    @EnvironmentObject var menuManager: MenuManager
    @EnvironmentObject var orderManager: OrderManager

    var body: some View {
        Group {
            if !orderManager.hasData {
                Spinner()
            } else {
                List {
                    ForEach(orderManager.orders) { order in
                        NavigationLink(destination: KitchenOrderDetailView(order: order)) {
                            OrderListCell(order: order)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .animation(.default, value: orderManager.orders.count)
            }
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.inline)
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
        RestaurantOrder(restaurantID: restaurant.id, id: "O3", state: .fulfilled,
                        table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                        createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O4", state: .cancelled,
                        table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                        createdAt: Date(), parts: []),
    ])
    static var layout = Layout(zones: [
        "Z": Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id),
    ], tables:  [
        Table.FullID(zone: "Z", table: "T"):
            Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z"),
    ])

    static var previews: some View {
        KitchenOrderListView()
            .environment(\.currentRestaurant, restaurant)
            .environment(\.currentLayout, .constant(layout))
            .environmentObject(menuManager)
            .environmentObject(orderManager)
    }
}
#endif
