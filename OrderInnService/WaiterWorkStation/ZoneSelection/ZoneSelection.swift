//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct ZoneSelection: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var zoneWork = ZoneWork()
    @State var alertItem: AlertItem?
    @State var showFinishedOrders = false
    
    var body: some View {
        ZStack{
            if !zoneWork.loadingQuery{
                if authManager.restaurant.subscriptionPaid{
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
                        .navigationBarHidden(true)
                }
            }else{
                Spinner()
            }
            NavigationLink(destination: TableSelectionView(zones: zoneWork), isActive: $zoneWork.goToTableView, label: {
                EmptyView()
            })
            //TODO: Create order cloasing.
            NavigationLink(destination: Text("Hello!"), isActive: $showFinishedOrders){
                EmptyView()
            }
        }
        .navigationBarItems(trailing: HStack{
            Button(action: {
                if authManager.waiter!.manager {
                    self.showFinishedOrders.toggle()
                } else {
                    self.alertItem = UIAlerts.restrictions
                }
            }, label: {
                Image(systemName: "folder")
                    .font(.custom("SF Symbols", size: 20))
                    .foregroundColor(.blue)
            })
        })
        .alert(item: $alertItem){ alert in
            Alert(title: alert.title, message: alert.message, dismissButton: alert.dismissButton)
        }
        .onAppear{
            zoneWork.getZones(for: authManager.restaurant)
        }
    }
}
