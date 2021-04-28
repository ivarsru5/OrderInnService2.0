//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import SwiftUI

struct ActiveOrderOverview: View {
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @ObservedObject var activeOrder: ActiveTableWork
    @State var displayActionSheet = false
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
                Section(header: Text("Submited Item's")){
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
                
                Text("EUR\(orderOverview.submitedOrder.totalPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
            
            NavigationLink(destination: MenuView(table: TableSelectionWork()), isActive: $showMenu) { EmptyView() }
        }
        .navigationTitle("SelectedZone")
        .navigationBarItems(trailing:
                                EditButton()
                                .simultaneousGesture(TapGesture().onEnded{
                                    self.displayActionSheet.toggle()
                                })
        )
        .onAppear{
            orderOverview.retreveSubmitedIttems(from: activeOrder.selectedOrder!)
        }
        .actionSheet(isPresented: $displayActionSheet, content: {
                        let buttons: [ActionSheet.Button] = [
                            .default(Text("Add more Items"), action: { self.showMenu.toggle() }),
                            .cancel({ self.displayActionSheet.toggle() })
                        ]
            return ActionSheet(title: Text("Edit Options"), buttons: buttons)
        })
    }
}
