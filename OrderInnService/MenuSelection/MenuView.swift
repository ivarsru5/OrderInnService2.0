//
//  MenuView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI

struct MenuView: View {
    @StateObject var menuOverview = MenuOverViewWork()
    @ObservedObject var table: TableSelectionWork
    
    var body: some View {
        ZStack{
            List{
                ForEach(menuOverview.menuCategory, id:\.id){ category in
                    Button(action: {
                        self.menuOverview.category = category
                        self.menuOverview.getMenuItems(with: category)
                    }, label: {
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("\(table.selectedTabel!.table)")
        .onAppear{
            menuOverview.getMenuCategory()
        }
        .sheet(isPresented: $menuOverview.presentMenu){
            MenuItemView(menuOverView: menuOverview)
        }
    }
}

struct MenuItemView: View {
    @ObservedObject var menuOverView: MenuOverViewWork
    
    var body: some View{
        ZStack{
            List{
                ForEach(menuOverView.menuItems, id: \.id){ item in
                    HStack{
                    Text(item.name)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(item.price)")
                        .bold()
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
