//
//  KitchenTabView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import Combine
import SwiftUI

struct KitchenTabView: View {
    @StateObject var menuManager: MenuManager
    @StateObject var orderManager: OrderManager
    let restaurant: Restaurant

    // HACK[pn 2021-08-03]: See Waiter/TabView.
    fileprivate init(restaurant: Restaurant) {
        self.restaurant = restaurant
        self._menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))
        self._orderManager = StateObject(wrappedValue: OrderManager(for: restaurant, scope: .all))
    }
    struct Wrapper: View {
        @Environment(\.currentRestaurant) var restaurant: Restaurant?
        var body: some View {
            IfLet(restaurant) { restaurant in
                KitchenTabView(restaurant: restaurant)
            }
        }
    }

    var body: some View {
        RestaurantLayoutLoader(restaurant: restaurant) {
            TabView {
                NavigationView {
                    KitchenOrderListView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Image(systemName: "tray")
                    Text("Orders")
                }

                NavigationView {
                    ItemAvailabilityView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Image(systemName: "tray")
                    Text("Availability")
                }

                #if DEBUG
                DebugMenu.navigationViewWithTabItem
                #endif
            }
        }
        .environmentObject(menuManager)
        .environmentObject(orderManager)
    }
}
