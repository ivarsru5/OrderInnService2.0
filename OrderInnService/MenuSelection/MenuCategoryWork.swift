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
    @Published var menuItems = [MenuItem]()
    @Published var presentMenu = false
    let database = Firestore.firestore()
    
    @Published var category: MenuCategory?{
        didSet{
            self.presentMenu.toggle()
        }
    }
    
    func getMenuCategory(){
        database.collection("Restaurants").document(UserDefaults.standard.qrStringKey).collection("MenuCategory").getDocuments { snapshot, error in
            guard let documentSnapshot = snapshot?.documents else {
                print("There is no categorys")
                return
            }
            self.menuCategory = documentSnapshot.compactMap{ categorySnapshot -> MenuCategory? in
                return MenuCategory(snapshot: categorySnapshot)
            }
        }
    }
    
    func getMenuItems(with categoryID: MenuCategory){
        database.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("MenuCategory")
            .document(categoryID.id)
            .collection("Menu")
            .getDocuments { snapshot, error in
                guard let documentSnapshot = snapshot?.documents else{
                    print("There is no menu Items")
                    return
                }
                self.menuItems = documentSnapshot.compactMap{ menuItemSnapshot -> MenuItem? in
                    return MenuItem(snapshot: menuItemSnapshot)
                }
            }
    }
}

