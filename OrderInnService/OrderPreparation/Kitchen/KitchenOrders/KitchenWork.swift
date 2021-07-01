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
    
    var kitchenOrders = [KitchenOrder]()
    var databse = Firestore.firestore()
    
    init(){
        self.getOrders { order in
            self.collectedOrders.append(order)
            self.collectedOrders.sort { !$0.orderOpened && $1.orderOpened }
        }
    }
    
    func getOrders(completion: @escaping (ClientSubmittedOrder) -> Void){
        
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .addSnapshotListener { snapshot, error in
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no orders")
                    return
                }
                self.collectedOrders.removeAll()
                
                for order in snapshotDocument{
                    self.retriveExtraOrders(from: order) { extraOrders in
                        guard let collectedOrder = KitchenOrder(snapshot: order, extraOrders: extraOrders) else{
                            return
                        }
                        
                        guard let decodedOrder = self.decodeOrder(order: collectedOrder) else{
                            return
                        }
                        completion(decodedOrder)
                    }
                }
            }
        }
    
    func retriveExtraOrders(from order: DocumentSnapshot, completion: @escaping([ActiveExtraOrder]) -> Void){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("ExtraOrder")
            .whereField("forOrder", isEqualTo: order.documentID)
            .addSnapshotListener { snapshot, error in
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no extra orders!")
                    return
                }
                
                let extraOrders = snapshotDocument.compactMap { order -> ActiveExtraOrder? in
                    guard let collectedExtraOrders = ActiveExtraOrder(snapshot: order) else{
                        return nil
                    }
                    return collectedExtraOrders
                }
                completion(extraOrders)
            }
        }
    
    func decodeOrder(order: KitchenOrder) -> ClientSubmittedOrder?{

            let formatter = DateFormatter()
            let date = order.created.dateValue()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
            let formattedStamp = formatter.string(from: date)

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

            let itemCount = items.count + extraOrders.count

            if itemCount > 0{
                return ClientSubmittedOrder(id: order.id,
                                            placedBy: order.placedBy,
                                            orderOpened: order.orderOpened,
                                            orderClosed: order.orderReady,
                                            totalPrice: order.totalPrice,
                                            forTable: order.forTable,
                                            inZone: order.forZone,
                                            created: formattedStamp,
                                            withItems: items,
                                            withExtraItems: extraOrders)
            }else{
                return nil
        }
    }

    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
