//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import SwiftUI

struct KitchenOrderOverView: View {
    @StateObject var orderOverview = KitchenOrderWork()
    @ObservedObject var activeOrder: KitchenWork
    @Binding var dismissOrderView: Bool
    
    var body: some View {
        ZStack{
                VStack{
                    HStack{
                        HStack{
                            Text("Table: ")
                                .bold()
                            
                            Text(activeOrder.selectedOrder!.forTable)
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    VStack{
                        
                        List{
                            ForEach(activeOrder.selectedOrder!.withExtraItems, id: \.id){ order in
                                Section(header: Text("Extra order: \(order.extraOrderPart!)")){
                                    ForEach(order.withItems, id: \.id){ item in
                                        HStack{
                                            Text(item.itemName)
                                                .bold()
                                                .foregroundColor(Color(UIColor.label))

                                            Spacer()

                                            Text("\(item.itemPrice, specifier: "%.2f")EUR")
                                                .italic()
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                    }
                                }
                            }
                            
                            Section(header: Text("Submited item's")){
                                ForEach(activeOrder.selectedOrder!.withItems, id: \.id){ item in
                                    SubmittedOrderCell(itemName: item.itemName, itemPrice: item.itemPrice!)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    Button(action: {
                        orderOverview.deleteOrder(fromOrder: activeOrder.selectedOrder!)
                    }, label: {
                        Text("order completed")
                            .bold()
                            .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                   minHeight: 0, idealHeight: 45, maxHeight: 55,
                                   alignment: .center)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .background(Color(UIColor.label))
                            .cornerRadius(15)
                    })
                    .padding()
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(activeOrder.selectedOrder!.inZone)
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                        self.dismissOrderView.toggle()
                                    }, label: {
                                        Text("Return")
                                            .bold()
                                            .foregroundColor(.red)
                                    })
                                })
        .onAppear{
            orderOverview.markOrderAsRead(forOrder: activeOrder.selectedOrder!)
        }
    }
}
