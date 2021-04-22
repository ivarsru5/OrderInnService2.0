//
//  QrCodeScannerWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import FirebaseFirestore

class QrCodeScannerWork: ObservableObject{
    @Published var restaurant = Restaurant()
    @Published var users = [Restaurant.RestaurantEmploye]()
    @Published var displayUsers = false
    @Published var loadingQuery = true
    let databse = Firestore.firestore()
    
    @Published var qrCode: String = ""{
        didSet{
            self.displayUsers.toggle()
        }
    }
    
    @Published var currentUser: Restaurant.RestaurantEmploye?{
        didSet{
            let user = "\(String(describing: currentUser?.name)) " + "\(String(describing: currentUser?.lastName))"
            UserDefaults.standard.currentUser = user
        }
    }

    
    func retriveRestaurant(with id: String){
        UserDefaults.standard.qrStringKey = id
        databse.collection("Restaurants").document(id).getDocument{ document, error in
            
            if let document = document{
                let dataDescription = document.data().map(String.init(describing: )) ?? nil
                print("Document Data: \(String(describing: dataDescription))")
                
                let id = document.documentID
                let name = document.data()!["name"] as? String ?? ""
                let subscription = document.data()!["subscriptionPaid"] as? Bool ?? true
                
                self.restaurant = Restaurant(id: id, name: name, subscriptionPaid: subscription)
                
            }else if error != nil{
                print("There is no document")
            }
        }
        self.getUsers(with: id)
    }
    
    func getUsers(with id: String){
        databse.collection("Restaurants").document(id).collection("Users").getDocuments { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no documents")
                return
            }
            let collectedUsers = snapshotDocument.compactMap { userSnapshot -> Restaurant.RestaurantEmploye? in
                guard let collectedEmployee = Restaurant.RestaurantEmploye(snapshot: userSnapshot) else{
                    //TODO: Display alert
                    return nil
                }
                return collectedEmployee
            }
            self.users = collectedUsers.filter({ $0.isActive != false })
            self.loadingQuery = false
        }
    }
    
    func updateData(with userId: Restaurant.RestaurantEmploye){
        databse.collection("Restaurants").document(qrCode).collection("Users").document(userId.id).updateData([
            "isActive" : false
        ]) { (error) in
            if let err = error{
                print("Error updating document \(err)")
            }else{
                print("Document successfuly updated.")
            }
        }
    }
}
