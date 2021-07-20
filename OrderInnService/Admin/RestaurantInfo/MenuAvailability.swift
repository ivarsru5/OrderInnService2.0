//
//  MenuAvailability.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 20/07/2021.
//

import SwiftUI

struct MenuAvailability: View {
    @ObservedObject var menu = MenuOverViewWork()
    
    var body: some View {
        VStack{
            MenuAvailabilityView(menuOverview: menu)
                .onAppear{
                    menu.getMenuCategory()
                }
        }
        .navigationTitle("Menu Availability")
    }
}

struct MenuAvailabilityView: View{
    @ObservedObject var menuOverview: MenuOverViewWork
    
    var body: some View{
        List{
            Section(header: Text("Meal's").font(.headline)){
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
                            MenuAvailabilityItemCell(menuItem: item)
                                .padding(.leading, 30)
                        }
                    }
                }
            }
            Section(header: Text("Drinks").font(.headline)){
                ForEach(Array(self.menuOverview.menuDrinks.enumerated()), id: \.element){ index ,category in
                    Button(action: {
                        self.menuOverview.menuDrinks[index].isExpanded.toggle()
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
                        ForEach(category.drinks, id: \.id) { item in
                            MenuAvailabilityItemCell(menuItem: item)
                                .padding(.leading, 30)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct MenuAvailabilityItemCell: View{
    var menuItem: MenuItem
    
    var body: some View{
        
        HStack{
            Image(systemName: "circle.fill")
                .font(.custom("SF Symbols", size: 10))
                .foregroundColor(Color(UIColor.label))
            
            Text(menuItem.name)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            if !menuItem.available{
                Text("No Stocks")
                    .bold()
                    .foregroundColor(.red)
            }
        }
        .padding(.all, 5)
    }
}
