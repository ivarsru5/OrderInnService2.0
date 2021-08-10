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

    // HACK[pn 2021-07-30]: Due to Swift's strict but sensible initialisation
    // rules, it's nigh impossible for us to obtain a reference to the
    // AuthManager from environment in order to initialise MenuManager with
    // the restaurant therein, therefore we require the restaurant to be passed
    // into here explicitly.
    init(authManager: AuthManager) {
        let restaurant = authManager.restaurant!
        self.restaurant = restaurant
        _menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))

        let employee = authManager.waiter!
        let subscriptionScope = OrderManager.SubscriptionScope(defaultFor: employee)
        _orderManager = StateObject(wrappedValue: OrderManager(for: restaurant, scope: subscriptionScope))
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
        .environment(\.currentRestaurant, restaurant)
        .onReceive(notificationPublisher) { _ in
            withAnimation {
                selectedTab = .activeOrders
            }
        }
    }
}
