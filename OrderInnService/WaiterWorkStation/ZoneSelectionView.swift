//
//  ZoneSelectionView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Combine
import SwiftUI

struct ZoneSelectionView: View {
    @Environment(\.currentLayout) @Binding var layout: Layout
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var menuManager: MenuManager

    struct CellData: Identifiable {
        enum Value {
            case zone(Zone)
            case table(Table)
        }
        let value: Value
        let layout: Layout!

        init(zone: Zone, layout: Layout) {
            self.value = .zone(zone)
            self.layout = layout
        }
        init(table: Table) {
            self.value = .table(table)
            self.layout = nil
        }

        var label: String {
            switch value {
            case .zone(let zone): return zone.location
            case .table(let table): return table.name
            }
        }

        var id: String {
            switch value {
            case .zone(let zone): return zone.id
            case .table(let table): return table.fullID.string
            }
        }

        var descendants: [CellData]? {
            guard case .zone(let zone) = value else { return nil }
            let tables = layout.orderedTables(in: zone)
            return tables.map { CellData(table: $0) }
        }
    }

    var cells: [CellData] {
        return layout.orderedZones.map { CellData(zone: $0, layout: layout) }
    }

    @State var hasNavigated = false
    @State var dismissNotificationPublisher = NotificationCenter.default.publisher(
        for: WaiterTabView.switchToActiveOrdersFlow, object: nil)

    var body: some View {
        List(cells, children: \.descendants) { cell in
            let view = Text(cell.label).bold()
            if case .table(let table) = cell.value {
                NavigationLink(destination: MenuView.Wrapper(context: .newOrder(table: table)),
                               isActive: $hasNavigated,
                               label: { view })
            } else {
                view
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Zones"))
        .navigationBarItems(trailing: HStack {
            if authManager.waiter?.isManager ?? false {
                NavigationLink(destination: Text("Hello world! (Please replace with manager view)")) {
                    Image(systemName: "folder")
                        .foregroundColor(.link)
                }
            }
        })
        .onReceive(dismissNotificationPublisher) { _ in
            hasNavigated = false
        }
    }
}
