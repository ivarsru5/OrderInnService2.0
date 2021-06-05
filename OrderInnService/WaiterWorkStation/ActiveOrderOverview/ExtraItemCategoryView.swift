//
//  ExtraItemView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 28/04/2021.
//

import SwiftUI

struct ExtraItemCategoryView: View {
    @StateObject var menuOverview = MenuOverViewWork()
    @ObservedObject var activeOrderOverview: ActiveOrderOverviewWork
    @ObservedObject var activeOrder: ActiveOrderWork
    
    var body: some View {
        VStack{
            ExtraMenuItemView(menuOverview: menuOverview, activeOrderOverview: activeOrderOverview)
        }
        .navigationTitle(activeOrder.selectedOrder!.forTable)
        .onAppear{
            menuOverview.getMenuCategory()
        }
    }
}

struct ExtraItemCell: View{
    @ObservedObject var activeOrderOverview: ActiveOrderOverviewWork
    @ObservedObject var menuOverview: MenuOverViewWork
    @State var itemAmount = 0
    var menuItem: MenuItem
    
    var body: some View{
        HStack{
            Text(menuItem.name)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            HStack{
                Button(action: {
                    activeOrderOverview.removeExtraItem(menuItem)
                    self.itemAmount = activeOrderOverview.getItemCount(forItem: menuItem)
                }, label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.custom("SF Symbols", size: 35))
                        .foregroundColor(Color(UIColor.label))
                })
                .buttonStyle(PlainButtonStyle())
                
                Text("\(itemAmount)")
                
                Button(action: {
                    activeOrderOverview.addExtraItem(menuItem)
                    self.itemAmount = activeOrderOverview.getItemCount(forItem: menuItem)
                }, label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.custom("SF Symbols", size: 35))
                        .foregroundColor(Color(UIColor.label))
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.all, 5)
        .onAppear{
            self.itemAmount = activeOrderOverview.getItemCount(forItem: menuItem)
        }
    }
}

struct ExtraMenuItemView: View{
    @ObservedObject var menuOverview: MenuOverViewWork
    @ObservedObject var activeOrderOverview: ActiveOrderOverviewWork
    
    var body: some View{
        List{
            ForEach(Array(self.menuOverview.menuCategory.enumerated()), id: \.element){ index ,category in
                Button(action: {
                    self.menuOverview.menuCategory[index].isExpanded.toggle()
                }, label: {
                    
                    HStack{
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                        
                        Spacer()
                        
                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(Color(UIColor.label))
                            .font(.custom("SF Symbols", fixedSize: 20))
                            .rotationEffect(Angle(degrees: category.isExpanded ? 90 : 0))
                            .animation(.linear(duration: 0.1), value: category.isExpanded)
                    }
                    .padding()
                })
                .listRowBackground(Color.secondary)
                
                if category.isExpanded{
                    ForEach(category.menuItems, id: \.id) { item in
                        ExtraItemCell(activeOrderOverview: activeOrderOverview, menuOverview: menuOverview, menuItem: item)
                    }
                }
            }
        }
    }
}
