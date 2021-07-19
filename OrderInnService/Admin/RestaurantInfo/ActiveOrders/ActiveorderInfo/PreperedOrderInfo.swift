//
//  PreperedOrderInfo.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import SwiftUI

struct PreperedOrderInfo: View {
    @Environment (\.presentationMode) var presentationMode
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @ObservedObject var activeOrder: ActiveOrders
    
    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text("Table: ")
                        .bold()
                    
                    Text(activeOrder.selectedOrder!.forTable)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack{
                    Text("Order created:")
                        .bold()
                    
                    Text(activeOrder.selectedOrder!.placedBy)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            
            VStack{
                List{
                    ForEach(orderOverview.collectedOrder.withExtraItems, id: \.id){ order in
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
                        ForEach(orderOverview.collectedOrder.withItems, id: \.id){ item in
                            SubmittedOrderCell(itemName: item.itemName, itemPrice: item.itemPrice!)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            
            HStack{
                Text("Total Order Amount")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                Text("EUR\(orderOverview.totalCollectedOrderPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
        }
        .navigationTitle(activeOrder.selectedOrder!.forZone)
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Text("Done")
                                            .bold()
                                            .foregroundColor(.blue)
                                    })
                                })
        .onAppear{
            orderOverview.retreveSubmitedItems(from: activeOrder.selectedOrder!)
        }
    }
}
