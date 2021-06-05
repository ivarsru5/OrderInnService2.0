//
//  ItemAvailability.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import SwiftUI

struct ItemAvailability: View {
    @StateObject var menuWork = MenuOverViewWork()
    @State var changeItemStatus = false
    
    var body: some View {
        VStack{
            List{
                ForEach(Array(self.menuWork.menuCategory.enumerated()), id: \.element){ index ,category in
                    Button(action: {
                        self.menuWork.menuCategory[index].isExpanded.toggle()
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
                            HStack{
                                Image(systemName: "circle.fill")
                                    .font(.custom("SF Symbols", size: 10))
                                    .foregroundColor(Color(UIColor.label))
                                
                                Text(item.name)
                                    .bold()
                                    .foregroundColor(Color(UIColor.label))
                                
                                Spacer()
                                
                                Text(item.available ? "Is Available" : "Not Available")
                                    .bold()
                                    .foregroundColor(item.available ? Color.green : Color.red)
                            }
                            .padding(.all, 5)
                            .actionSheet(isPresented: $changeItemStatus) {
                                ActionSheet(title: Text("Change item status"), message: Text("Are you sure you want to chage item availability?"), buttons: [
                                    .default(Text("Change")) {
                                        self.menuWork.changeItemAvailability(inCategory: category, item: item)
                                        //self.menuWork.getMenuCategory()
                                    },
                                    .cancel()
                                ])
                            }
                            .onTapGesture{
                                self.changeItemStatus.toggle()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Menu Availability")
        .onAppear{
            menuWork.getMenuCategory()
        }
    }
}
