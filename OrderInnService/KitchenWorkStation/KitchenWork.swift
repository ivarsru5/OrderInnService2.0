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
                
                let kitchenItems = snapshotDodument.compactMap { activeOrderSnapshot -> ActiveOrder? in
                    guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                        return nil
                    }
                    return collectedOrder
                }
                
                let activeKitchenItems = kitchenItems.map{ order -> OrderOverview in
                    var items = [OrderOverview.OrderOverviewEntry]()
                    
                    let orderItems = order.kitchenItems.map{ item -> OrderOverview.OrderOverviewEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        
                        let collectedItem = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: nil)
                        return collectedItem
                    }
                    items.append(contentsOf: orderItems)
                    
                    let collectedOrder = OrderOverview(id: order.id, placedBy: order.placedBy, orderCompleted: order.orderCompleted, orderClosed: order.orderClosed, totalPrice: order.totalPrice, forTable: order.forTable, inZone: order.forZone, withItems: items)
                    return collectedOrder
                }
                self.activeOrder = activeKitchenItems
            }
        }
    
    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
