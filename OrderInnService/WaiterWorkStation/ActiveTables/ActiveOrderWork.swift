//
//  ActiveOrderWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Foundation
import FirebaseFirestore

class ActiveTableWork: ObservableObject{
    @Published var activeOrders = [ActiveOrder]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    @Published var selectedOrder: ActiveOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    func retriveActiveOrders(){
        databse.collection("Restaurants").document(UserDefaults.standard.qrStringKey).collection("Order").getDocuments { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no documents")
                return
            }
            
            self.activeOrders = snapshotDocument.compactMap { activeOrderSnapshot in
                guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                    return nil
                }
                return collectedOrder
            }
        }
    }
}
