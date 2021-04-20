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
            if !zoneWork.loadingQuery{
                List{
                    ForEach(zoneWork.zones, id: \.id){ zone in
                        NavigationLink(destination: EmptyView()){
                            Text("\(zone.location)")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        }
                    }
                }
                .navigationTitle(Text("Zone's"))
                .navigationBarBackButtonHidden(true)
            }else{
                Spinner()
            }
        }
        .onAppear{
            qrScanner.retriveRestaurant(with: UserDefaults.standard.qrStringKey)
            zoneWork.getZones()
            print(String(describing: UserDefaults.standard.currentUser))
        }
    }
}
