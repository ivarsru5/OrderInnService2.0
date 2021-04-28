//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import SwiftUI

struct ActiveOrderOverview: View {
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @ObservedObject var activeOrder: ActiveOrderWork
    @State var showMenu = false
    
    var body: some View {
        VStack{
            HStack{
                HStack{
                    Text("Table: ")
                        .bold()
                    
                    Text(activeOrder.selectedOrder!.forTable)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding()
            
            List{
                if !orderOverview.menuItems.isEmpty{
                    Section(header: Text("Selected extra item's")){
                        ForEach(orderOverview.menuItems, id:\.id){ item in
                            HStack{
                                Text(item.name)
                                    .bold()
                                    .foregroundColor(Color(UIColor.label))
                                
                                Spacer()
                                HStack{
                                    Text("\(item.price,specifier: "%.2f")EUR")
                                        .italic()
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    Button(action: {
                                        withAnimation(.easeOut(duration: 0.5)){
                                            orderOverview.removeExtraItem(item)
                                        }
                                    }, label: {
                                        Image(systemName: "xmark.circle")
                                            .font(.custom("SF Symbols", size: 20))
                                            .foregroundColor(.blue)
                                    })
                                }
                            }
                        }
                    }
                }else{
                    EmptyView()
                }
                
                    ForEach(orderOverview.extraOrderComponents, id:\.index){ extra in
                        Section(header: Text("Submited extra order : \(extra.index)")){
                            ForEach(extra.menuItems, id: \.id){ item in
                                HStack{
                                    Text(item.name)
                                        .bold()
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    Spacer()
                                    
                                    Text("\(item.price,specifier: "%.2f")EUR")
                                        .italic()
                                        .foregroundColor(Color(UIColor.label))
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Submited item's")){
                        ForEach(orderOverview.submitedOrder.withItems, id: \.id){ item in
                            HStack{
                                Text(item.itemName)
                                    .bold()
                                    .foregroundColor(Color(UIColor.label))
                                
                                Spacer()
                                
                                Text("\(item.itemPrice,specifier: "%.2f")EUR")
                                    .italic()
                                    .foregroundColor(Color(UIColor.label))
                            }
                        }
                    }
                }
                
            HStack{
                Text("Total Order Amount")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                Text("EUR\(orderOverview.submitedOrder.totalPrice + orderOverview.extraOrderTotalPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
            
            NavigationLink(destination: ExtraItemCategoryView(activeOrderOverview: orderOverview, activeOrder: activeOrder), isActive: $showMenu) { EmptyView() }
            
            HStack{
                if !orderOverview.menuItems.isEmpty{
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)){
                            _ = orderOverview.addExtraItems()
                        }
                    }, label: {
                        Text("Submit extra order")
                            .bold()
                            .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                   minHeight: 0, idealHeight: 32, maxHeight: 54,
                                   alignment: .center)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .background(Color(UIColor.label))
                            .cornerRadius(15)
                    })
                    .padding()
                }
                
                Button(action: {
                    self.showMenu.toggle()
                }, label: {
                    Text("Add items to Order")
                        .bold()
                        .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                               minHeight: 0, idealHeight: 32, maxHeight: 54,
                               alignment: .center)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .background(Color(UIColor.label))
                        .cornerRadius(15)
                })
                .padding()
            }
        }
        .navigationTitle("SelectedZone")
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                        self.activeOrder.showActiveOrder.toggle()
                                    }, label: {
                                        Text("Done")
                                            .bold()
                                            .foregroundColor(.blue)
                                    })
                                })
        .onAppear{
            orderOverview.retreveSubmitedIttems(from: activeOrder.selectedOrder!)
        }
    }
}
