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
    
    @Published var selectedOrder: ClientSubmittedOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    var activeOrders = [KitchenOrder]()
    var databse = Firestore.firestore()
    
    func retriveActiveOrders(fromKey: QrCodeScannerWork?){
        activeOrders.removeAll()
        let group = DispatchGroup()
        
        if fromKey != nil{
            UserDefaults.standard.kitchenQrStringKey = fromKey!.restaurantQrCode
        }
        
        group.enter()
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .getDocuments { snapshot, error in
    
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no documents")
                    group.leave()
                    return
                }
    
                for document in snapshotDocument{
                    var activeExtraOrder = [ActiveExtraOrder]()
    
                    group.enter()
                    self.databse.collection("Restaurants")
                        .document(UserDefaults.standard.kitchenQrStringKey)
                        .collection("ExtraOrder").whereField("forOrder", isEqualTo: document.documentID)
                        .getDocuments { snapshot, error in
                            
                            guard let snapshotDocument = snapshot?.documents else{
                                group.leave()
                                return
                            }
    
                            for extraOrder in snapshotDocument{
                                guard let collectedExtraOrder = ActiveExtraOrder(snapshot: extraOrder) else{
                                    return
                                }
                                activeExtraOrder.append(collectedExtraOrder)
                            }
    
                            guard let collectedOrder = KitchenOrder(snapshot: document, extraOrders: activeExtraOrder) else{
                                return
                            }
    
                            self.activeOrders.append(collectedOrder)
    
                            group.leave()
                        }
                }
                group.leave()
            }
    
        group.notify(queue: .main){
            self.collectedOrders = self.activeOrders.map{ order -> ClientSubmittedOrder in
    
                let items = order.kitchenItems.map { item -> OrderOverview.OrderOverviewEntry in
                    let seperator = "/"
                    let partParts = item.components(separatedBy: seperator)
                    let itemName = partParts[0]
                    let itemPrice = Double(partParts[1])
    
                    let collectedItem = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice)
                    return collectedItem
                }
    
                let extraOrders = order.withExtras.map{ extraOrder -> ExtraOrderOverview in
    
                    let extraItems = extraOrder.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])
    
                        return ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice!)
                    }
    
                    return ExtraOrderOverview(id: extraOrder.id,
                                              extraOrderPart: extraOrder.extraOrderPart,
                                              extraPrice: extraOrder.extraOrderPrice,
                                              forOrder: extraOrder.orderId,
                                              withItems: extraItems)
                }
    
                return ClientSubmittedOrder(id: order.id,
                                            placedBy: order.placedBy,
                                            orderCompleted: order.orderCompleted,
                                            orderClosed: order.orderClosed,
                                            totalPrice: order.totalPrice,
                                            forTable: order.forTable,
                                            inZone: order.forZone,
                                            withItems: items,
                                            withExtraItems: extraOrders)
            }
        }
    }

    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
