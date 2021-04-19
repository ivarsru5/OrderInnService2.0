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
    @Published var currentUser: Restaurant.RestaurantEmploye?
    @Published var displayUsers = false
    @Published var loadingQuery = true
    let databse = Firestore.firestore()
    
    @Published var qrCode: String = ""{
        didSet{
            self.displayUsers.toggle()
        }
    }

    
    func retriveRestaurant(with id: String){
        let documentReferance = databse.collection("Restaurants").document(id)
        documentReferance.getDocument(source: .cache) { document, error in
            DispatchQueue.main.async {
                if let document = document{
                    let dataDescription = document.data().map(String.init(describing: )) ?? nil
                    print("Document Data: \(String(describing: dataDescription))")

                    let id = document.documentID
                    let name = document.data()!["name"] as? String ?? ""

                    self.restaurant.id = id
                    self.restaurant.name = name
                    self.restaurant.documentReferance = documentReferance
                    
                }else if error != nil{
                    print("There is no document")
                }
            }
        }
    }
    
    func getUsers(with id: String){
        databse.collection("Restaurants").document(id).collection("Users").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no documents")
                    return
                }
                let collectedUsers = snapshotDocument.map { userSnapshot -> Restaurant.RestaurantEmploye in
                    let data = userSnapshot.data()
                    
                    let id = userSnapshot.documentID
                    let name = data["name"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    let isActive = data["isActive"] as? Bool ?? true

                    return Restaurant.RestaurantEmploye(id: id, name: name, lastName: lastName, isActive: isActive)
                }
                self.users = collectedUsers.filter({ $0.isActive != false })
                self.loadingQuery = false
            }
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
