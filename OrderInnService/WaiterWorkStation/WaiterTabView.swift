//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Combine
import SwiftUI

struct WaiterTabView: View {
    static let switchToActiveOrdersFlow = Notification.Name("O6N.waiter.switchToActiveOrdersFlow")

    enum Selection: Hashable {
        case placeOrder
        case activeOrders
        case managerView
        #if DEBUG
        case debugMenu
        #endif
    }

    @Environment(\.currentRestaurant) var restaurant: Restaurant?
    @Environment(\.currentEmployee) var employee: Restaurant.Employee?
    @StateObject var menuManager: MenuManager
    @StateObject var orderManager: OrderManager
    @State var notificationPublisher = NotificationCenter.default.publisher(
        for: WaiterTabView.switchToActiveOrdersFlow, object: nil)
    @State var selectedTab: Selection = .placeOrder

    fileprivate init(restaurant: Restaurant, waiter: Restaurant.Employee) {
        _menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))

        let subscriptionScope = OrderManager.SubscriptionScope(defaultFor: waiter)
        _orderManager = StateObject(wrappedValue: OrderManager(for: restaurant, scope: subscriptionScope))
    }
    struct Wrapper: View {
        @Environment(\.currentRestaurant) var restaurant: Restaurant?
        @Environment(\.currentEmployee) var waiter: Restaurant.Employee?

        var body: some View {
            IfLet(restaurant.zip(waiter)) { (restaurant, waiter) in
                WaiterTabView(restaurant: restaurant, waiter: waiter)
            }
        }
    }

    var body: some View {
        IfLet(restaurant.zip(employee)) { (restaurant, _) in
            RestaurantLayoutLoader(restaurant: restaurant) {
                if menuManager.hasData {
                    _body
                } else {
                    Spinner()
                }
            }
        }
    }

    private var _body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ZoneSelectionView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Place Order", systemImage: "tray")
            }
            .tag(Selection.placeOrder)

            NavigationView {
                ActiveOrderListView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Active Orders", systemImage: "scroll")
            }
            .tag(Selection.activeOrders)

            if employee!.isManager {
                NavigationView {
                    ManagerView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Manager Controls", systemImage: "folder")
                }
                .tag(Selection.managerView)
            }

            #if DEBUG
            DebugMenu.withTabItem
                .tag(Selection.debugMenu)
            #endif
        }
        .environmentObject(menuManager)
        .environmentObject(orderManager)
        .onReceive(notificationPublisher) { _ in
            withAnimation {
                selectedTab = .activeOrders
            }
        }
    }
}
