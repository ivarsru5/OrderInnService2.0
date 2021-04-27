//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct ZoneSelection: View {
    @ObservedObject var qrScanner: QrCodeScannerWork
    @StateObject var zoneWork = ZoneWork()
    
    var body: some View {
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
        .onAppear{
            qrScanner.retriveRestaurant(with: UserDefaults.standard.qrStringKey)
            zoneWork.getZones()
            print(UserDefaults.standard.currentUser)
        }
    }
}
