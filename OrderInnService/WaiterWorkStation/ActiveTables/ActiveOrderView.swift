//
//  ActiveOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct ActiveOrderView: View {
    @StateObject var activeOrders = ActiveTableWork()
    
    var body: some View {
        VStack{
            List{
                Section(header: Text("Active Order")){
                    ForEach(activeOrders.activeOrders, id: \.id){ order in
                        HStack{
                            Text(order.placedBy)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .navigationTitle("Active Orders")
        .onAppear{
            activeOrders.retriveActiveOrders()
        }
    }
}

struct ActiveOrderView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveOrderView()
    }
}
