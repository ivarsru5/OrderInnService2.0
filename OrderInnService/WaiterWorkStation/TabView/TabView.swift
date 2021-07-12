//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct OrderTabView: View {
    var body: some View {
        TabView {
            NavigationView { ZoneSelection() }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "tray")
                Text("Place Order")
            }

            NavigationView{ ActiveOrderView() }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "scroll")
                Text("Active Order's")
            }

            #if DEBUG
            DebugMenu.navigationViewWithTabItem
            #endif
        }
    }
}
