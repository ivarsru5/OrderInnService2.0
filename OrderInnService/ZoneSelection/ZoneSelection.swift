//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct ZoneSelection: View {
    @EnvironmentObject var qrScanner: QrCodeScannerWork
    @StateObject var zoneWork = ZoneWork()
    
    var body: some View {
        NavigationView{
            ZStack{
                if !zoneWork.loadingQuery{
                    if qrScanner.restaurant.subscriptionPaid{
                        List{
                            ForEach(zoneWork.zones, id: \.id){ zone in
                                Button(action: {
                                    self.zoneWork.selectedZone = zone
                                }, label: {
                                    Text("\(zone.location)")
                                        .bold()
                                        .foregroundColor(Color(UIColor.label))
                                })
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .navigationTitle(Text("Zone's"))
                        .navigationBarBackButtonHidden(true)
                    }else{
                        Text("Sorry for inconvenience! It seems that subscription paymant is due.")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(UIColor.label))
                    }
                }else{
                    Spinner()
                }
                NavigationLink(destination: TableSelectionView(zones: zoneWork), isActive: $zoneWork.goToTableView, label: {
                    EmptyView()
                })
            }
        }
        .onAppear{
            qrScanner.retriveRestaurant(with: UserDefaults.standard.qrStringKey)
            zoneWork.getZones()
            print(String(describing: UserDefaults.standard.currentUser))
        }
    }
}

struct NavigationButton<Destination: View, Label: View>: View {
    var action: () -> Void = { }
    var destination: () -> Destination
    var label: () -> Label

    @State private var isActive: Bool = false

    var body: some View {
        Button(action: {
            self.action()
            self.isActive.toggle()
        }) {
            self.label()
              .background(
                ScrollView {
                    NavigationLink(destination: LazyDestination { self.destination() },
                                                 isActive: self.$isActive) { EmptyView() }
                }
              )
        }
    }
}

struct LazyDestination<Destination: View>: View {
    var destination: () -> Destination
    var body: some View {
        self.destination()
    }
}
