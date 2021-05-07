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
    @Published var submittedExtraOrder = [ExtraOrderOverview]()
    @Published var showActiveOrder = false
    let databse = Firestore.firestore()
    
    @Published var selectedOrder: ActiveOrder?{
        didSet{
            self.showActiveOrder.toggle()
        }
    }
    
    func retriveActiveOrders(){
        databse.collection("Restaurants").document(UserDefaults.standard.wiaterQrStringKey).collection("Order").addSnapshotListener { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no documents")
                return
            }
            
            self.activeOrders = snapshotDocument.compactMap { activeOrderSnapshot -> ActiveOrder? in
                guard let collectedOrder = ActiveOrder(snapshot: activeOrderSnapshot) else{
                    return nil
                }
                self.getExtraOrders(from: collectedOrder)
                return collectedOrder
            }
        }
    }
    
    func getExtraOrders(from order: ActiveOrder){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.wiaterQrStringKey)
            .collection("ExtraOrder").whereField("forOrder", isEqualTo: order.id)
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
                    
                    let barItems = order.extraBarItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    extraOrderEntry.append(contentsOf: barItems)
                    
                    let collectedOrder = ExtraOrderOverview(id: order.id, extraOrderPart: order.extraOrderPart, extraPrice: order.extraOrderPrice, forOrder: order.orderId, withItems: extraOrderEntry)
                    return collectedOrder
            }
                self.submittedExtraOrder = extraOrder.sorted { $0.extraOrderPart! > $1.extraOrderPart! }
        }
    }
    
    func checkForKitchenItems(kitchenItems: [ActiveOrder], extraItems: [ExtraOrderOverview]) -> Bool{
        var result: Bool = true
        for item in kitchenItems{
            if item.kitchenItems.isEmpty{
                result = false
            }else{
                result = true
            }
        }
        
        return result
    }

    func getRestaurantName(fromQrString: String) -> String{
        let seperator = "-"
        let path = fromQrString.components(separatedBy: seperator)
        let restaurant = path[0]
        return restaurant
    }
}
