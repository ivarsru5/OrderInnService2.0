//
//  ActiveOrderWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Foundation
import FirebaseFirestore

class ActiveOrderWork: ObservableObject{
    @Published var activeOrders = [ActiveOrder]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    @Published var selectedOrder: ActiveOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    func retriveActiveOrders(){
        databse.collection("Restaurants").document(UserDefaults.standard.wiaterQrStringKey).collection("Order").getDocuments { snapshot, error in
            
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
            self.activeOrders = collectdeTables.filter{ $0.placedBy == UserDefaults.standard.currentUser }
        }
    }
}
