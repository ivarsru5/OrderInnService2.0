//
//  ZoneSelection.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct ZoneSelection: View {
    @StateObject var zoneWork = ZoneWork()
    var restaurant: Restaurant
    
    var body: some View {
        VStack{
            List{
                ForEach(zoneWork.zones, id: \.id){ zone in
                    NavigationLink(destination: EmptyView()){
                        Text("\(zone.location)")
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
            .onAppear{
                guard let referance = restaurant.documentReferance else{
                    return
                }
                zoneWork.getZones(with: referance)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(Text("Zone's"))
    }
}
