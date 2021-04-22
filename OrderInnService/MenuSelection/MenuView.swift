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
        VStack{
            HStack{
                Text(menuOverView.category!.name)
                    .bold()
                    .foregroundColor(Color(UIColor.label))
                    .font(.subheadline)
                    .padding(.all, 15)
                
                Spacer()
            }
            ScrollView{
                ForEach(menuOverView.menuItems, id: \.id){ item in
                    MenuItemCell(menuItem: item)
                }
            }
        }
    }
}

struct MenuItemCell: View{
    var menuItem: MenuItem
    
    var body: some View{
        ZStack{
            Rectangle()
                .frame(height: 70)
                .foregroundColor(Color(UIColor.systemGray3))
                .cornerRadius(20)
            
            HStack{
                Image(systemName: "circle.fill")
                    .font(.custom("SF Symbols", size: 10))
                    .foregroundColor(Color(UIColor.label))
                
                Text(menuItem.name)
                    .bold()
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                HStack{
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.custom("SF Symbols", size: 30))
                            .foregroundColor(Color(UIColor.label))
                    })
                    
                    Text("0")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.custom("SF Symbols", size: 30))
                            .foregroundColor(Color.white)
                    })
                }
            }
            .padding()
        }
        .padding(.leading, 15)
        .padding(.trailing, 15)
    }
}
