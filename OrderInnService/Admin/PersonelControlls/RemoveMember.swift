//
//  RemoveMember.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import SwiftUI
import Combine
#if DEBUG
import Dispatch
#endif

struct RemoveMember: View {
    @EnvironmentObject var authManager: AuthManager
    @State var users: [Restaurant.Employee]? = nil

    #if DEBUG
    var mockRemoval: Bool = false
    #endif

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
    @State var isUserBeingRemoved = false
    func deleteUser() {
        guard let user = userToRemove else { return }
        guard let index = users?.firstIndex(where: { $0.id == user.id }) else { return }

        #if DEBUG
        if mockRemoval {
            isUserBeingRemoved = true
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(3))) {
                withAnimation {
                    userToRemove = nil
                    isUserBeingRemoved = false
                    users!.remove(at: index)
                }
            }
            return
        }
        #endif

        isUserBeingRemoved = true
        var sub: AnyCancellable?
        sub = user.delete()
            .mapError { error in
                // TODO[pn 2021-07-29]
                fatalError("FIXME Failed to delete user: \(String(describing: error))")
            }
            .flatMap { _ -> AnyPublisher<[Restaurant.Employee], Error> in
                withAnimation {
                    userToRemove = nil
                    isUserBeingRemoved = false
                    users!.remove(at: index)
                }
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

    @ViewBuilder func userListingIconOverlay(_ isBeingRemoved: Bool) -> some View {
        if isBeingRemoved {
            ActivityIndicator(style: .medium)
        } else {
            EmptyView()
        }
    }
    @ViewBuilder func userListing() -> some View {
        List {
            ForEach(users!) { user in
                let isBeingRemoved = userToRemove?.id == user.id && isUserBeingRemoved

                Button(action: {
                    userToRemove = user
                }, label: {
                    Label(title: {
                        Text(verbatim: user.fullName)
                            .foregroundColor(isBeingRemoved ? .secondaryLabel : .label)
                    }, icon: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.label)
                            .bodyFont(size: 24)
                            .padding(6)
                            .opacity(isBeingRemoved ? 0.0 : 1.0)
                            .overlay(userListingIconOverlay(isBeingRemoved))
                    })
                })
                .disabled(isBeingRemoved)
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
            Text(verbatim: authManager.restaurant.name)
                .bold()
                .foregroundColor(.label)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .top, .trailing])

            if users == nil {
                Spinner()
            } else if users!.isEmpty {
                Text("No personnel has been added.\nYou can add personnel in the “Manage Personnel” section.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .center)
                    .padding()
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
            RemoveMember(users: [])

            RemoveMember(users: users,
                         mockRemoval: true)
        }
        .environmentObject(authManager)
    }
}
#endif
