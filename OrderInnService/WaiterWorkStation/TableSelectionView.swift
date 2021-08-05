//
//  TableSelectionView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Combine
import SwiftUI

struct TableSelectionView: View {
    @Environment(\.currentLayout) @Binding var layout: Layout
    @EnvironmentObject var menuManager: MenuManager
    let zone: Zone

    var body: some View {
        List {
            ForEach(layout.orderedTables(in: zone)) { table in
                NavigationLink(destination: MenuView(menuManager: menuManager,
                                                     context: .newOrder(table: table))) {
                    Text(table.name)
                        .bold()
                        .foregroundColor(Color.label)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(zone.location)
    }
}
