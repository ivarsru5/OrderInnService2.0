//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Combine
import SwiftUI

struct ZoneSelection: View {
    class Model: ObservableObject {
        @Published var zones: [Zone] = []
        @Published var isLoading = true
        var sub: AnyCancellable?

        func loadZones() {
            sub = AuthManager.shared.restaurant.firestoreReference
                .collection(of: Zone.self)
                .get()
                .catch { error in
                    // TODO[pn 2021-07-16]
                    return Empty().setFailureType(to: Never.self)
                }
                .collect()
                .sink(receiveValue: { [unowned self] zones in
                    self.zones = zones.sorted(by: \.location)
                    self.isLoading = false
                    self.sub = nil
                })
        }
    }

    @EnvironmentObject var authManager: AuthManager
    @StateObject var model = Model()

    var zoneList: some View {
        List {
            ForEach(model.zones) { zone in
                NavigationLink(destination: TableSelectionView(zone: zone)) {
                    Text(zone.location)
                        .bold()
                        .foregroundColor(Color.label)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Zones"))
    }

    var body: some View {
        Group {
            if model.isLoading {
                Spinner()
            } else {
                zoneList
            }
        }
        .navigationBarItems(trailing: HStack {
            if authManager.waiter?.manager ?? false {
                NavigationLink(destination: Text("Hello world! (Please replace with admin view)")) {
                    Image(systemName: "folder")
                        .foregroundColor(.link)
                }
            }
        })
        .onAppear {
            if model.isLoading {
                model.loadZones()
            }
        }
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
