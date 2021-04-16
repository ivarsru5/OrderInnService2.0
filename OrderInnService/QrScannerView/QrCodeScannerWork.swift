//
//  QrCodeScannerWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Combine
import FirebaseFirestore

class QrCodeScannerWork: ObservableObject{
    @Published var restaurant: Restaurant?
    @Published var alertItem: AlertItem?
    let objectWillChange = PassthroughSubject<Void, Never>()
    let databse = Firestore.firestore()
    
    @Published var qrCode: String = ""{
        didSet{
            objectWillChange.send()
        }
    }
    
    func retriveEmployes(withId: String){
        
        databse.collection("Restaurants").document(qrCode).getDocument { (document, error) in
            
            if let document = document, document.exists{
                let dataDescription = document.data().map(String.init(describing: )) ?? nil
                print("Document Data: \(String(describing: dataDescription))")
                
                let id = document.documentID
                let name = document.data()!["name"] as? String ?? ""
                
                self.restaurant = Restaurant(id: id, name: name)
                
            }else if error != nil{
                print("There is no document")
            }
        }
    }
}
