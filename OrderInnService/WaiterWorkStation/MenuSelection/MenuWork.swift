//
//  MenuCategoryWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI
import FirebaseFirestore

class MenuOverViewWork: ObservableObject{
    @Published var menuCategory = [MenuCategory]()
    @Published var menuDrinks = [MenuDrinks]()
    let database = Firestore.firestore()
    
    func getMenuCategory(){
        var menu = [MenuCategory]()
        let group = DispatchGroup()
        
        group.enter()
        database.collection("Restaurants")
            .document(UserDefaults.standard.wiaterQrStringKey)
            .collection("MenuCategory")
            .getDocuments { snapshot, error in
                guard let documentSnapshot = snapshot?.documents else {
                    print("There is no categorys")
                    group.leave()
                    return
                }
                
                for document in documentSnapshot{
                    var menuItems = [MenuItem]()
                    
                    group.enter()
                    self.database.collection("Restaurants")
                        .document(UserDefaults.standard.wiaterQrStringKey)
                        .collection("MenuCategory")
                        .document(document.documentID)
                        .collection("Menu")
                        .getDocuments { snapshot, error in
                            guard let documentSnapshot = snapshot?.documents else{
                                print("There is no menu Items")
                                group.leave()
                                return
                            }
                            
                            for item in documentSnapshot{
                                guard let items = MenuItem(snapshot: item) else{
                                    return
                                }
                                menuItems.append(items)
                            }
                            guard let category = MenuCategory(snapshot: document, menuItems: menuItems) else{
                                return
                            }
                            menu.append(category)
                            group.leave()
                        }
                }
                group.leave()
            }
        group.notify(queue: .main){
            self.menuDrinks = menu.compactMap { item -> MenuDrinks? in
                guard item.type == "drink" else{
                    return nil
                }
                
                let drinks = MenuDrinks(name: item.name, drinks: item.menuItems)
                return drinks
            }
            self.menuCategory = menu.filter { $0.type == "food" }
        }
    }
}

