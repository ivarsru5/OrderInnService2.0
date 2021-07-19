//
//  ActiveOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct ActiveOrderView: View {
    @StateObject var activeOrders = ActiveOrderWork()
    @State var destanation: TargetDestanation? = nil
    
    var body: some View {
        ZStack{
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
            }else{
                Text("There is no active orders. Please make one to view activity.")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("Active Orders")
        .onAppear{
            activeOrders.retriveActiveOrders()
        }
        .fullScreenCover(item: $destanation){ destanation in
            NavigationView{
                switch destanation{
                case .toActiveOrder:
                    ActiveOrderOverview(activeOrder: activeOrders)
                case .toPreperedOrder:
                    PreperedOrderView(preperedOrders: activeOrders)
                }
            }
        }
    }
}

enum TargetDestanation: Hashable, Identifiable{
    case toActiveOrder
    case toPreperedOrder
    
    var id: Int{
        return self.hashValue
    }
}
