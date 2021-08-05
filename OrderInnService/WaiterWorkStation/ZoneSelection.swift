//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Combine
import SwiftUI

struct ZoneSelection: View {
    @Environment(\.currentLayout) @Binding var layout: Layout
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        List {
            ForEach(layout.orderedZones) { zone in
                NavigationLink(destination: TableSelectionView(zone: zone)) {
                    Text(zone.location)
                        .bold()
                        .foregroundColor(Color.label)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Zones"))
        .navigationBarItems(trailing: HStack {
            if authManager.waiter?.manager ?? false {
                NavigationLink(destination: Text("Hello world! (Please replace with manager view)")) {
                    Image(systemName: "folder")
                        .foregroundColor(.link)
                }
            }
        })
    }

    static var navigationViewWithTabItem: some View {
        NavigationView {
            ZoneSelection()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tabItem {
            Image(systemName: "tray")
            Text("Place Order")
        }
    }
}
