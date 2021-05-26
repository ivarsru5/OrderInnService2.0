//
//  OrderOverViewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import Foundation
import FirebaseFirestore

class KitchenOrderWork: ObservableObject{
    let databse = Firestore.firestore()
    
    func deleteOrder(fromOrder: ClientSubmittedOrder){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .document(fromOrder.id)
            .delete(){ error in
                if let error = error{
                    print("Document was not deleted \(error)")
                }else{
                    print("Extra Orders deleted.")
                    for order in fromOrder.withExtraItems{
                        let orderID = order.forOrder
                        
                        if orderID == fromOrder.id{
                            self.databse.collection("Restaurants")
                                .document(UserDefaults.standard.kitchenQrStringKey)
                                .collection("ExtraOrder")
                                .document(order.id)
                                .delete() { error in
                                    if let error = error{
                                        print("Document was not deleted \(error)")
                                    }else{
                                        print("Extra Orders deleted.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func markOrderAsRead(forOrder: ClientSubmittedOrder){
        databse.collection("Restaurants").document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .document(forOrder.id)
            .updateData([
                "orderOpened" : true
            ]) { error in
                if let err = error{
                    print("Error updating document \(err)")
                }else{
                    print("Order opened")
            }
        }
    }
}
