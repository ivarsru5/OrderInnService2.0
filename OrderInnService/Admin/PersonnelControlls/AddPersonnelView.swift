//
//  AddPersonnelView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/07/2021.
//

import Combine
import SwiftUI

struct AddPersonnelView: View {
    @EnvironmentObject var authManager: AuthManager
    @State var firstName = ""
    @State var lastName = ""
    @State var isManager = false
    @State var sendingQuery = false
    
    func addPersonel() {
        sendingQuery = true

        var sub: AnyCancellable?
        sub = Restaurant.Employee.create(under: authManager.restaurant,
                                         fullName: "\(firstName) \(lastName)",
                                         isManager: isManager)
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
                isManager = false
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

                Toggle(isOn: $isManager, label: {
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
        AddPersonnelView()
    }
}
#endif
