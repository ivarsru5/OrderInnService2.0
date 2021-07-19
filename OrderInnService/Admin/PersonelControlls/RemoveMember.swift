//
//  RemoveMember.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct RemoveMember: View {
    @EnvironmentObject var authManager: AuthManager
    
    class Controlls: ObservableObject{
        @Published var members: [Restaurant.Employee]?
        @Published var displayActionSheet = false
        
        @Published var user: Restaurant.Employee?{
            didSet{
                self.displayActionSheet.toggle()
            }
        }
        
        var _loadUsersCancellable: AnyCancellable!
        var _finishLoginCancellable: AnyCancellable!

        func loadUsers(from authManager: AuthManager) {
            _loadUsersCancellable = authManager.restaurant.loadUsers().sink(receiveCompletion: {
                [unowned self] result in
                self._loadUsersCancellable = nil
                // TODO: handle case .failure(let error) = result...
            }, receiveValue: { [unowned self] members in
                self.members = members
            })
        }
    }
    
    @StateObject var controlls = Controlls()
    
    @ViewBuilder func userListing(restaurant: Restaurant, users: [Restaurant.Employee]) -> some View {
        List{
            ForEach(users) { user in
                Button(action: {
                    controlls.user = user
                }, label: {
                    HStack{
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color(UIColor.label))
                            .font(.custom("SF Symbols", size: 20))
                            .padding(.all, 5)

                        Text("\(user.name) \(user.lastName)")
                            .foregroundColor(Color(UIColor.label))
                            .padding(.all, 10)
                    }
                })
            }
            .actionSheet(isPresented: $controlls.displayActionSheet) {
                ActionSheet(title: Text("Revoke access to member"),
                            message: Text("Are you sure you want to revoke access to this team member?"),
                            buttons: [
                                .default(Text("Revoke")){ authManager.restaurant.deleteUser(memberID: controlls.user!.id) },
                                .cancel()
                            ])
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(restaurant.name)
        .onReceive(controlls.$members, perform: { _ in
            controlls.loadUsers(from: authManager)
        })
    }
    
    var body: some View {
        VStack {
            IfLet(controlls.members, whenPresent: { users in
                if users.count == 0 {
                    Text("You dont have any personel. You can add them in 'Manage personel section'")
                } else {
                    userListing(restaurant: authManager.restaurant, users: users)
                }
            }, whenAbsent: {
                Spinner()
            })
        }
        .onAppear {
            controlls.loadUsers(from: authManager)
        }
    }
}

struct RemoveMember_Previews: PreviewProvider {
    static var previews: some View {
        RemoveMember()
    }
}
