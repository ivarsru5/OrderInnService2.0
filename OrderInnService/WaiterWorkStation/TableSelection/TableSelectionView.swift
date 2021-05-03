//
//  TableSelectionView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI

struct TableSelectionView: View {
    @ObservedObject var restaurantOrder = RestaurantOrderWork()
    @StateObject var tables = TableSelectionWork()
    @ObservedObject var zones: ZoneWork
    
    var body: some View {
        
        ZStack{
            if !tables.loadingQuery{
                List{
                    ForEach(tables.tables, id:\.id){ table in
                        Button(action: {
                            self.tables.selectedTabel = table
                        }, label: {
                            Text("\(table.table)")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                    }
                }
                .navigationBarTitle(Text("\(zones.selectedZone!.location)"))
                .listStyle(InsetGroupedListStyle())
                .onAppear{
                    tables.getTables(with: zones.selectedZone!)
                }
            }else{
                Spinner()
            }
            NavigationLink(destination: MenuView(table: tables, zone: zones), isActive: $tables.goToMenu){ EmptyView() }
        }
        .onAppear{
            restaurantOrder.restaurantOrder.menuItems.removeAll()
            restaurantOrder.totalPrice = 0.00
        }
    }
}
