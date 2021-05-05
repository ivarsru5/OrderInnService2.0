//
//  KitchenWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 05/05/2021.
//

import Foundation
import FirebaseFirestore


class KitchenWork: ObservableObject{
    @Published var collectedOrder = [ClientSubmittedOrder]()
    @Published var activeKitchenOrders = [ActiveOrder]()
    @Published var activeOrder = [OrderOverview]()
   // @Published var submittedExtraOrder = [ExtraOrderOverview]()
    let databse = Firestore.firestore()
    
    var items = [OrderOverview.OrderOverviewEntry]()
    var submittedExtraOrder = [ExtraOrderOverview]()
    
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
                    
                    let orderItems = order.kitchenItems.map{ item -> OrderOverview.OrderOverviewEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        
                        let collectedItem = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: nil)
                        return collectedItem
                    }
                    self.items.append(contentsOf: orderItems)
                    
                    let collectedOrder = OrderOverview(id: order.id, placedBy: order.placedBy, orderCompleted: order.orderCompleted, orderClosed: order.orderClosed, totalPrice: order.totalPrice, forTable: order.forTable, inZone: order.forZone, withItems: self.items)
                    
                    self.getExtraOrderItems(fromOrder: order)
                    
                    return collectedOrder
                }
                self.activeOrder = activeKitchenItems
                self.collectAllOrders(order: self.activeOrder,
                                      withItems: self.items,
                                      withExtraItems: self.submittedExtraOrder)
            }
        }
    
    func getExtraOrderItems(fromOrder: ActiveOrder){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("ExtraOrder").whereField("forOrder", isEqualTo: fromOrder.id)
            .addSnapshotListener { snapshot, error in
                
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no documents")
                    return
                }
                
                let activeExtraOrders = snapshotDocument.compactMap{ activeExtras -> ActiveExtraOrder? in
                    guard let collectedExtras = ActiveExtraOrder(snapshot: activeExtras) else{
                        return nil
                    }
                    return collectedExtras
                }
                
                let extraOrder = activeExtraOrders.map{ order -> ExtraOrderOverview in
                    var extraOrderEntry = [ExtraOrderOverview.ExtraOrderEntry]()
                    
                    let kitchenItems = order.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    extraOrderEntry.append(contentsOf: kitchenItems)
                    
                    let collectedOrder = ExtraOrderOverview(id: order.id,
                                                            extraOrderPart: order.extraOrderPart,
                                                            extraPrice: order.extraOrderPrice,
                                                            forOrder: order.orderId,
                                                            withItems: extraOrderEntry)
                    return collectedOrder
                }
                self.submittedExtraOrder = extraOrder
            }
    }
    
    func collectAllOrders(order: [OrderOverview], withItems: [OrderOverview.OrderOverviewEntry], withExtraItems: [ExtraOrderOverview]){
        self.collectedOrder = order.map{ order -> ClientSubmittedOrder in
            let collectedOrder = ClientSubmittedOrder(id: order.id,
                                             placedBy: order.placedBy,
                                             orderCompleted: order.orderCompleted,
                                             orderClosed: order.orderClosed,
                                             totalPrice: order.totalPrice,
                                             forTable: order.forTable,
                                             inZone: order.inZone,
                                             withItems: withItems,
                                             withExtraItems: withExtraItems)
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
