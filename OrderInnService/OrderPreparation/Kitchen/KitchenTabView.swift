//
//  KitchenTabView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import SwiftUI

struct KitchenTabView: View {
    @StateObject var menuManager: MenuManager

    // HACK[pn 2021-08-03]: See Waiter/TabView.
    init(restaurant: Restaurant) {
        self._menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))
    }


    var body: some View {
        TabView {
            NavigationView {
                KitchenView()
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
        .environmentObject(menuManager)
    }
}
