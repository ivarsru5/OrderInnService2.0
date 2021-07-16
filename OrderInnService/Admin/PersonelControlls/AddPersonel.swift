//
//  AddPersonel.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/07/2021.
//

import SwiftUI
import FirebaseFirestore

struct AddPersonel: View {
    @State var firstName = ""
    @State var lastName = ""
    @State var manager = false
    @State var sendingQuery = false
    
    func addPersonel(name: String, lastName: String, manager: Bool){
        sendingQuery = true
        
        let documentData: [String: Any] = [
            "isActive": false,
            "name" : name,
            "lastName" : lastName,
            "manager" : manager
        ]
        
        Firestore.firestore()
            .collection("Restaurants")
            .document(UserDefaults.standard.wiaterQrStringKey)
            .collection("Users")
            .addDocument(data: documentData) { error in
                if let err = error{
                    print("Document did not create \(err)")
                }else{
                    print("User created!")
                    self.firstName = ""
                    self.lastName = ""
                    self.manager = false
                    self.sendingQuery = false
                }
            }
    }
    
    var body: some View {
        if !sendingQuery{
            VStack{
                Form{
                    Section{
                        TextField("First Name", text: $firstName)
                        TextField("Last Name", text: $lastName)
                    }
                    
                    Toggle(isOn: $manager, label: {
                        Text("Place manager status")
                    })
                }
                Button(action: {
                    if !firstName.isEmpty && !lastName.isEmpty{
                        self.addPersonel(name: firstName, lastName: lastName, manager: manager)
                    }else{
                        //TODO: Show alert
                    }
                }, label: {
                    Text("Add member")
                        .bold()
                        .frame(width: 250, height: 50, alignment: .center)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .background(Color(UIColor.label))
                        .cornerRadius(15)
                })
                .padding(.top, 30)
            }
            .navigationTitle("Add member")
        } else{
            Spinner()
        }
    }
}

struct AddPersonel_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonel()
    }
}
