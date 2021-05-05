//
//  KitchenWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 05/05/2021.
//

import Foundation
import FirebaseFirestore


class KitchenWork: ObservableObject{
    @Published var activeKitchenOrders = [ActiveOrder]()
    @Published var activeOrder = [OrderOverview]()
    let databse = Firestore.firestore()
    
    func getKitchenOrder(_ qrScanner: QrCodeScannerWork){
        UserDefaults.standard.kitchenQrStringKey = qrScanner.restaurantQrCode
        
        databse.collection("Restaurants").document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .addSnapshotListener { snapshot, error in
                guard let snapshotDodument = snapshot?.documents else{
                    return
                }
                
                self.activeKitchenOrders = snapshotDodument.compactMap { activeOrderSnapshot -> ActiveOrder? in
                    guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                        return nil
                    }
                    return collectedOrder
                }
            }
        
        retriveKitchenOrder()
    }
    
    func retriveKitchenOrder(){
        self.activeOrder = activeKitchenOrders.map { order -> OrderOverview in
            let menuItems = order.kitchenItems.map { item -> OrderOverview.OrderOverviewEntry in
                let seperator = "/"
                let partParts = item.components(separatedBy: seperator)
                let itemName = partParts[0]
                
                let collectedItems = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: nil)
                return collectedItems
            }
            let collectedOrder = OrderOverview(id: order.id, placedBy: order.placedBy, orderCompleted: order.orderCompleted, orderClosed: order.orderClosed, totalPrice: order.totalPrice, forTable: order.forTable, inZone: order.forZone, withItems: menuItems)
            return collectedOrder
        }
    }
    
    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
