//
//  General.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/07/2021.
//

import SwiftUI

struct AdminGeneralSelection: View {
    func navigationLink<Destination: View>(destination: Destination, label: Text) -> some View {
        return NavigationLink(destination: destination) {
            label
                .bold()
                .foregroundColor(.label)
        }
    }
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Manage Personnel")) {
                    navigationLink(destination: AddPersonnelView(),
                                   label: Text("Add Member"))
                    navigationLink(destination: RemovePersonnelView(),
                        label: Text("Revoke Access to Member"))
                }
                
                Section(header: Text("Restaurant Info")) {
                    navigationLink(
//                        destination: RestaurantActiveOrders(),
                        destination: EmptyView(),
                        label: Text("Active Orders"))
                    
                    navigationLink(destination: EmptyView(),
                        label: Text("Closed Order History"))
                    
                }
                
                Section(header: Text("In-App Controls")) {
                    navigationLink(destination: EmptyView(),
                        label: Text("Make an Order"))

                    navigationLink(destination: EmptyView(),
                        label: Text("Kitchen"))
                }

                #if DEBUG
                Section {
                    navigationLink(destination: DebugMenu()
                                    .navigationBarTitle(Text("Debug Menu"), displayMode: .inline),
                                   label: Text("Debug Menu"))
                }
                #endif
            }
            .navigationTitle(Text("General"))
        }
    }
}

#if DEBUG
struct General_Previews: PreviewProvider {
    static var previews: some View {
        AdminGeneralSelection()
    }
}
#endif
