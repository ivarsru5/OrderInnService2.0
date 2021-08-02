//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct OrderTabView: View {
    @StateObject var menuManager: MenuManager

    // HACK[pn 2021-07-30]: Due to Swift's strict but sensible initialisation
    // rules, it's nigh impossible for us to obtain a reference to the
    // AuthManager from environment in order to initialise MenuManager with
    // the restaurant therein, therefore we require the restaurant to be passed
    // into here explicitly.
    init(restaurant: Restaurant) {
        _menuManager = StateObject(wrappedValue: MenuManager(for: restaurant))
    }

    var body: some View {
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
        }
    }
}
