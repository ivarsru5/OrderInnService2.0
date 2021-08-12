//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Combine
import SwiftUI

struct OrderTabView: View {
    static let switchToActiveOrdersFlow = Notification.Name("O6N.waiter.switchToActiveOrdersFlow")

    enum Selection: Hashable {
        case placeOrder
        case activeOrders
        #if DEBUG
        case debugMenu
        #endif
    }

    let restaurant: Restaurant
    @StateObject var menuManager: MenuManager
    @StateObject var orderManager: OrderManager
    @State var notificationPublisher = NotificationCenter.default.publisher(
        for: OrderTabView.switchToActiveOrdersFlow, object: nil)
    @State var selectedTab: Selection = .placeOrder

    fileprivate init(restaurant: Restaurant, waiter: Restaurant.Employee) {
        self.restaurant = restaurant
        _menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))

        let subscriptionScope = OrderManager.SubscriptionScope(defaultFor: waiter)
        _orderManager = StateObject(wrappedValue: OrderManager(for: restaurant, scope: subscriptionScope))
    }
    struct Wrapper: View {
        @Environment(\.currentRestaurant) var restaurant: Restaurant!
        @Environment(\.currentEmployee) var waiter: Restaurant.Employee!

        var body: some View {
            OrderTabView(restaurant: restaurant, waiter: waiter)
        }
    }

    var body: some View {
        RestaurantLayoutLoader(restaurant: restaurant) {
            if !menuManager.hasData {
                Spinner()
            } else {
                TabView(selection: $selectedTab) {
                    NavigationView {
                        ZoneSelection()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "tray")
                        Text("Place Order")
                    }
                    .tag(Selection.placeOrder)

                    NavigationView {
                        ActiveOrderListView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "scroll")
                        Text("Active Orders")
                    }
                    .tag(Selection.activeOrders)

                    #if DEBUG
                    DebugMenu.withTabItem
                        .tag(Selection.debugMenu)
                    #endif
                }
                .environmentObject(menuManager)
                .environmentObject(orderManager)
            }
        }
        .onReceive(notificationPublisher) { _ in
            withAnimation {
                selectedTab = .activeOrders
            }
        }
    }
}
