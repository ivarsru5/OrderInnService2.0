//
//  General.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/07/2021.
//

import SwiftUI

struct AdminGeneralSelection: View {
    var body: some View {
        NavigationView{
            List{
                Section(header: Text("Manage personel")){
                    NavigationLink(
                        destination: AddPersonel(),
                        label: {
                            Text("Add member to team")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                                .padding(10)
                        })
                    NavigationLink(
                        destination: RemoveMember(),
                        label: {
                            Text("Revoke access to member")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                                .padding(10)
                        })
                }
                
                Section(header: Text("Restaurant info")){
                    NavigationLink(
//                        destination: RestaurantActiveOrders(),
                        destination: EmptyView(),
                        label: {
                            Text("Active restaurant orders")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                                .padding(10)
                        })
                    
                    NavigationLink(
                        destination: EmptyView(),
                        label: {
                            Text("Closed order history")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                                .padding(10)
                        })
                    
                    NavigationLink(
//                        destination: MenuAvailability(),
                        destination: EmptyView(),
                        label: {
                            Text("Menu availability")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                                .padding(10)
                        })
                    
                }

                #if DEBUG
                Section(header: Text("Debug Menu")) {
                    let destination = DebugMenu()
                        .navigationTitle("Debug Menu")
                    NavigationLink(destination: destination) {
                        Text("Debug Menu")
                            .bold()
                            .foregroundColor(.label)
                    }
                }
                #endif
            }
            .navigationTitle(Text("General"))
        }
    }
}


struct General_Previews: PreviewProvider {
    static var previews: some View {
        AdminGeneralSelection()
    }
}
