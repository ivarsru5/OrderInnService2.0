//
//  KitchenWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 05/05/2021.
//

import Foundation
import FirebaseFirestore

class KitchenWork: ObservableObject{
    @Published var activeOrders = [ActiveOrder]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    @Published var selectedOrder: ActiveOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    func retriveActiveOrders(){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .addSnapshotListener { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no documents")
                return
            }
            
            let collectdeTables = snapshotDocument.compactMap { activeOrderSnapshot -> ActiveOrder? in
                guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                    return nil
                }
                return collectedOrder
            }
                self.activeOrders = collectdeTables
        }
    }
    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
