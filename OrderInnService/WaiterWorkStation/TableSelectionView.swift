//
//  TableSelectionView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Combine
import SwiftUI

struct TableSelectionView: View {
    class Model: ObservableObject {
        @Published var tables: [Table] = []
        @Published var isLoading = true

        var sub: AnyCancellable?
        func loadTables(for zone: Zone) {
            sub = zone.firestoreReference
                .collection(of: Table.self)
                .get()
                .catch { error in
                    // TODO[pn 2021-07-16]
                    return Empty().setFailureType(to: Never.self)
                }
                .collect()
                .sink { [unowned self] tables in
                    self.tables = tables.sorted(by: \.name)
                    self.isLoading = false
                    self.sub = nil
                }
        }
    }

    @StateObject var model = Model()
    let zone: Zone

    var tableList: some View {
        List {
            ForEach(model.tables) { table in
                NavigationLink(destination: MenuView(context: .newOrder(table: table))) {
                    Text(table.name)
                        .bold()
                        .foregroundColor(Color.label)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    var body: some View {
        Group {
            if model.isLoading {
                Spinner()
            } else {
                tableList
            }
        }
        .navigationTitle(zone.location)
        .onAppear {
            if model.isLoading {
                model.loadTables(for: zone)
            }
        }
    }
}
