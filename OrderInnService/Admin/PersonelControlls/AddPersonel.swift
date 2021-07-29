//
//  AddPersonel.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/07/2021.
//

import Combine
import SwiftUI

struct AddPersonel: View {
    @EnvironmentObject var authManager: AuthManager
    @State var firstName = ""
    @State var lastName = ""
    @State var manager = false
    @State var sendingQuery = false
    
    func addPersonel() {
        sendingQuery = true

        var sub: AnyCancellable?
        sub = Restaurant.Employee.create(under: authManager.restaurant,
                                         name: firstName, lastName: lastName, manager: manager)
            .mapError { error in
                // TODO[pn 2021-07-29]
                fatalError("FIXME Failed to create employee: \(String(describing: error))")
            }
            .sink { _ in
                if let _ = sub {
                    sub = nil
                }
                firstName = ""
                lastName = ""
                manager = false
                sendingQuery = false
            }
    }

    var formComplete: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Toggle(isOn: $manager, label: {
                    Text("Enable Manager Status")
                })
            }
            Button(action: {
                guard formComplete else {
                    // TODO: Show alert
                    return
                }
                addPersonel()
            }, label: {
                Text("Add Member")
            })
                .buttonStyle(O6NButtonStyle(isLoading: sendingQuery,
                                            isEnabled: formComplete))
        }
        .navigationBarTitle("Add Member", displayMode: .inline)
    }
}

#if DEBUG
struct AddPersonel_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonel()
    }
}
#endif
