//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import SwiftUI

struct KitchenView: View {
    @StateObject var kitchen = KitchenWork()
    @ObservedObject var qrScanner: QrCodeScannerWork
    @State var showOrderOverview  = false
    
    var body: some View {
        ZStack{
            if !kitchen.collectedOrders.isEmpty{
                List{
                    Section(header: Text("Recived Orders")){
                        ForEach(kitchen.collectedOrders, id: \.id){ order in
                            Button(action: {
                                self.kitchen.selectedOrder = order
                                self.showOrderOverview.toggle()
                            }, label: {
                                HStack{
                                    HStack{
                                        Text("In Zone: ")
                                            .bold()
                                            .foregroundColor(Color(UIColor.label))
                                        
                                        Text(order.inZone)
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
                        .padding()
                    }
                }
            }else{
                Text("There have not been placed any order yet.")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            NavigationLink(destination: KitchenOrderOverView(activeOrder: kitchen, dismissOrderView: $showOrderOverview), isActive: $showOrderOverview) { EmptyView()}
        }
        .navigationTitle("\(kitchen.getRestaurantName(fromQrString: qrScanner.restaurantQrCode)): \(qrScanner.kitchen!)")
        .onAppear{
            kitchen.retriveActiveOrders(fromKey: qrScanner)
        }
    }
}

