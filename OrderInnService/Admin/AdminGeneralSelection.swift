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
                        })
                    NavigationLink(
                        destination: RemoveMember(),
                        label: {
                            Text("Revoke access to member")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                }
                
                Section(header: Text("Restaurant info")){
                    NavigationLink(
                        destination: RestaurantActiveOrders(),
                        label: {
                            Text("Active restaurant orders")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                    
                    NavigationLink(
                        destination: EmptyView(),
                        label: {
                            Text("Closed order history")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                    
                }
                
                Section(header: Text("In app controls")){
                    NavigationLink(
                        destination: EmptyView(),
                        label: {
                            Text("Make an order")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                    
                    NavigationLink(
                        destination: EmptyView(),
                        label: {
                            Text("Kitchen")
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        })
                }
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
