//
//  ActiveOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct ActiveOrderView: View {
    @StateObject var activeOrders = ActiveOrderWork()
    
    var body: some View {
        ZStack{
            if !activeOrders.activeOrders.isEmpty{
                List{
                    Section(header: Text("Active Order")){
                        ForEach(activeOrders.activeOrders, id: \.id){ order in
                            Button(action: {
                                self.activeOrders.selectedOrder = order
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
        .fullScreenCover(isPresented: $activeOrders.showActiveOrder){
            NavigationView{
                ActiveOrderOverview(activeOrder: activeOrders)
            }
        }
    }
}

struct ActiveOrderView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveOrderView()
    }
}
