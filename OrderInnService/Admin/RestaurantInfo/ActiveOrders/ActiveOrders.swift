//
//  ActiveOrders.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import Foundation
import FirebaseFirestore

#if false
class ActiveOrders: ObservableObject{
    @Published var activeOrders = [ActiveOrder]()
    @Published var preperedOrders = [ActiveOrder]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    @Published var selectedOrder: ActiveOrder?
    
    init(){
        self.retriveActiveOrders { activeOrders in
            self.activeOrders = activeOrders.filter { !$0.orderReady }
            self.preperedOrders = activeOrders.filter { $0.orderReady }
        }
    }
    
    func retriveActiveOrders(completion: @escaping ([ActiveOrder]) -> Void){
        databse.collection("Restaurants").document(UserDefaults.standard.wiaterQrStringKey).collection("Order").addSnapshotListener { snapshot, error in
            
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
            completion(collectdeTables)
        }
    }
}
#endif
