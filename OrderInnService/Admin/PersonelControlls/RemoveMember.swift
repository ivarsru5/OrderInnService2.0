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
    @State var isLoading = false
    @State var users: [Restaurant.Employee]? = nil

    func loadUsers() {
        var sub: AnyCancellable?
        sub = authManager.restaurant.loadUsers()
            .mapError { error in
                // TODO
                fatalError("FIXME Failed to load users for deletion: \(String(describing: error))")
            }
            .sink { users in
                if let _ = sub {
                    sub = nil
                }
                self.users = users
            }
    }

    @State var userToRemove: Restaurant.Employee? = nil
    func deleteUser() {
        guard let user = userToRemove else { return }

        isLoading = true
        var sub: AnyCancellable?
        sub = user.delete()
            .mapError { error in
                // TODO[pn 2021-07-29]
                fatalError("FIXME Failed to delete user: \(String(describing: error))")
            }
            .flatMap { _ -> AnyPublisher<[Restaurant.Employee], Error> in
                userToRemove = nil
                isLoading = false
                users = nil
                return authManager.restaurant.loadUsers()
            }
            .mapError { error in
                // TODO[pn 2021-07-29]
                fatalError("FIXME Failed to reload users after deletion: \(String(describing: error))")
            }
            .sink { users in
                if let _ = sub {
                    sub = nil
                }
                self.users = users
            }
    }

    @ViewBuilder func userListing() -> some View {
        Text(verbatim: authManager.restaurant.name)
            .bold()
            .foregroundColor(.label)
            .font(.largeTitle)
            .padding(.top)

        List {
            ForEach(users!) { user in
                Button(action: {
                    userToRemove = user
                }, label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.label)
                            .symbolSize(20)
                            .padding(.all, 5)

                        Text(verbatim: user.fullName)
                            .foregroundColor(.label)
                            .padding(.all, 10)
                    }
                })
            }
        }
        .actionSheet(isPresented: .constant(userToRemove != nil)) {
            ActionSheet(title: Text("Revoke Access to Member"),
                        message: Text("Are you sure you want to revoke access to this team member?"),
                        buttons: [
                            .destructive(Text("Revoke"), action: deleteUser),
                            .cancel(Text("Cancel"), action: { userToRemove = nil }),
                        ])
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    var body: some View {
        VStack {
            if users == nil || isLoading {
                Spinner()
            } else if users!.isEmpty {
                Text("You dont have any personel. You can add them in 'Manage personel section'")
            } else {
                userListing()
            }
        }
        .navigationBarTitle("Remove Member", displayMode: .inline)
        .onAppear {
            if users == nil {
                loadUsers()
            }
        }
    }
}

#if DEBUG
struct RemoveMember_Previews: PreviewProvider {
    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let authManager = AuthManager(debugWithRestaurant: restaurant, waiter: nil, kitchen: nil)
    static let users: [Restaurant.Employee] = [
        .init(restaurantID: restaurant.id, id: "E1", name: "Testuser", lastName: "1", manager: false, isActive: true),
        .init(restaurantID: restaurant.id, id: "E2", name: "Testuser", lastName: "2", manager: false, isActive: true),
        .init(restaurantID: restaurant.id, id: "E3", name: "Testuser", lastName: "3", manager: false, isActive: true),
    ]

    static var previews: some View {
        let _ = authManager.setAuthState(.authenticatedAdmin(restaurantID: restaurant.id, admin: ""))


        Group {
            RemoveMember(isLoading: false,
                         users: users,
                         userToRemove: nil)

            RemoveMember(isLoading: false,
                         users: users,
                         userToRemove: nil)
                .preferredColorScheme(.dark)
        }
            .environmentObject(authManager)
    }
}
#endif
