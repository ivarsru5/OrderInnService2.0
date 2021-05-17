//
//  KitchenWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 05/05/2021.
//

import Foundation
import FirebaseFirestore

class KitchenWork: ObservableObject{
    @Published var collectedOrders = [ClientSubmittedOrder]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    var extraOrder = [ActiveExtraOrder]()
    var order = [OrderOverview]()
    
    @Published var selectedOrder: ClientSubmittedOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    func retriveActiveOrders(fromKey: QrCodeScannerWork){
        let group = DispatchGroup()
        UserDefaults.standard.kitchenQrStringKey = fromKey.restaurantQrCode
        
        group.enter()
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .addSnapshotListener { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no documents")
                group.leave()
                return
            }
            
            let collectedOrders = snapshotDocument.compactMap { activeOrderSnapshot -> ActiveOrder? in
                guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                    return nil
                }
                self.getExtraOrders(from: collectedOrder, dispach: group)
                return collectedOrder
            }
                
                self.order = collectedOrders.map{ order -> OrderOverview in
                    let items = order.kitchenItems.map { item -> OrderOverview.OrderOverviewEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])
                        
                        let collectedItem = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    let collectedOrder = OrderOverview(id: order.id,
                                                       placedBy: order.placedBy,
                                                       orderCompleted: order.orderCompleted,
                                                       orderClosed: order.orderClosed,
                                                       totalPrice: order.totalPrice,
                                                       forTable: order.forTable,
                                                       inZone: order.forZone,
                                                       withItems: items)
                    return collectedOrder
                }
                group.leave()
        }
        
        group.notify(queue: .main){
            self.collectedOrders = self.order.map { order -> ClientSubmittedOrder in
                let extraPart = self.extraOrder.map { extra -> ExtraOrderOverview in
                    var extraOverview: ExtraOrderOverview!
                    
                    if extra.orderId == order.id{
                            let kitchenItems = extra.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                                let seperator = "/"
                                let partParts = item.components(separatedBy: seperator)
                                let itemName = partParts[0]
                                let itemPrice = Double(partParts[1])!
                                
                                let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                                return collectedItem
                            }
                        
                        extraOverview = ExtraOrderOverview(id: extra.id,
                                                           extraOrderPart: extra.extraOrderPart,
                                                           extraPrice: extra.extraOrderPrice,
                                                           forOrder: extra.orderId,
                                                           withItems: kitchenItems)
                    }
                    return extraOverview
                }
                
                let entry = ClientSubmittedOrder(id: order.id,
                                                 placedBy: order.placedBy,
                                                 orderCompleted: order.orderCompleted,
                                                 orderClosed: order.orderClosed,
                                                 totalPrice: order.totalPrice,
                                                 forTable: order.forTable,
                                                 inZone: order.inZone,
                                                 withItems: order.withItems,
                                                 withExtraItems: extraPart)
                return entry
            }
        }
    }
    
    func getExtraOrders(from order: ActiveOrder, dispach: DispatchGroup){
        dispach.enter()
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("ExtraOrder").whereField("forOrder", isEqualTo: order.id)
            .addSnapshotListener { snapshot, error in
                
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no documents")
                    dispach.leave()
                    return
                }
                
                self.extraOrder = snapshotDocument.compactMap{ activeExtras -> ActiveExtraOrder? in
                    guard let collectedExtras = ActiveExtraOrder(snapshot: activeExtras) else{
                        return nil
                    }
                    return collectedExtras
                }
                dispach.leave()
            }
    }
    
    
    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
