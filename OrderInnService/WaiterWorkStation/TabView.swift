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
            ZoneSelection.navigationViewWithTabItem
            ActiveOrderListView.navigationViewWithTabItem
            #if DEBUG
            DebugMenu.withTabItem
            #endif
        }
    }
}
