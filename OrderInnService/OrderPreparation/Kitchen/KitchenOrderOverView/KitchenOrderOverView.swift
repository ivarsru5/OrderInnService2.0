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
                                .foregroundColor(.white)
                            
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
                                            Image(systemName: "circle")
                                                .foregroundColor(Color(UIColor.label))
                                                .font(.custom("SF Symbols", size: 7.5))
                                            
                                            Text(item.itemName)
                                                .bold()
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                    }
                                }
                            }
                            
                            Section(header: Text("Submited item's")){
                                ForEach(orderOverview.collectedOrder.withItems, id: \.id){ item in
                                    MainOrderCell(itemName: item.itemName)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(activeOrder.selectedOrder!.forZone)
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
            orderOverview.retreveSubmitedItems(from: activeOrder.selectedOrder!)
        }
    }
}


struct MainOrderCell: View{
    var itemName: String
    
    var body: some View{
        HStack{
            Image(systemName: "circle")
                .foregroundColor(Color(UIColor.label))
                .font(.custom("SF Symbols", size: 7.5))
            
            Text(itemName)
                .bold()
                .foregroundColor(Color(UIColor.label))
        }
    }
}
