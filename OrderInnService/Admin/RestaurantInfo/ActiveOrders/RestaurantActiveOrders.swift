//
//  RestaurantActiveOrders.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import SwiftUI

#if false
struct RestaurantActiveOrders: View {
    @StateObject var activeOrders = ActiveOrders()
    @State var destanation: TargetDestanation? = nil
    
    var body: some View {
        VStack{
            if !activeOrders.activeOrders.isEmpty{
                List{
                    Section(header: Text("Active Order")){
                        ForEach(activeOrders.activeOrders, id: \.id){ order in
                            Button(action: {
                                self.activeOrders.selectedOrder = order
                                self.destanation = .toActiveOrder
                            }, label: {
                                HStack{
                                    HStack{
                                        Text("In Zone: ")
                                            .bold()
                                            .foregroundColor(Color(UIColor.label))
                                        
                                        Text(order.forZone)
                                            .bold()
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                    
                                    Spacer()
                                    
                                    HStack{
                                        Text("Table: ")
                                            .bold()
                                            .foregroundColor(.secondary)
                                        
                                        Text(order.forTable)
                                            .bold()
                                            .foregroundColor(.secondary)
                                    }
                                }
                            })
                        }
                    }
                    
                    if !activeOrders.preperedOrders.isEmpty{
                        Section(header: Text("Prepered Orders")){
                            ForEach(activeOrders.preperedOrders, id: \.id){ preperedOrder in
                                Button(action: {
                                    self.activeOrders.selectedOrder = preperedOrder
                                    self.destanation = .toPreperedOrder
                                }, label: {
                                    HStack{
                                        HStack{
                                            Text("In Zone: ")
                                                .bold()
                                                .foregroundColor(Color(UIColor.label))
                                            
                                            Text(preperedOrder.forZone)
                                                .bold()
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                        
                                        Spacer()
                                        
                                        HStack{
                                            Text("Table: ")
                                                .bold()
                                                .foregroundColor(.secondary)
                                            
                                            Text(preperedOrder.forTable)
                                                .bold()
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Active Orders")
        .fullScreenCover(item: $destanation){ destanation in
            NavigationView{
                switch destanation{
                case .toActiveOrder:
                    ActiveOrderInfoView(activeOrder: activeOrders)
                case .toPreperedOrder:
                    PreperedOrderInfo(activeOrder: activeOrders)
                }
            }
        }
    }
}
#endif
