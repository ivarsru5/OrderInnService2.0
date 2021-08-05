//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Combine
import SwiftUI

struct OrderTabView: View {
    let restaurant: Restaurant
    @StateObject var menuManager: MenuManager
    @StateObject var orderManager: OrderManager

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
                TabView {
                    ZoneSelection.navigationViewWithTabItem
                    ActiveOrderListView.navigationViewWithTabItem
                    #if DEBUG
                    DebugMenu.withTabItem
                    #endif
                }
                .environmentObject(menuManager)
                .environmentObject(orderManager)
            }
        }
    }
}
