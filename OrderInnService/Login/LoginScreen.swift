//
//  ContentView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Combine

struct LoginScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State var alertItem: AlertItem?

    var isAuthPendingUserSelection: Bool {
        switch authManager.authState {
        case .authenticatedWaiterUnknownID(restaurantID: _): return true
        default: return false
        }
    }
    var isAuthPendingUserSelectionBinding: Binding<Bool> {
        return .constant(isAuthPendingUserSelection)
    }
    var body: some View {
        ZStack {
            QRScannerView(alertItem: $alertItem)
                .edgesIgnoringSafeArea(.all)
            
            BlurEffectView(effect: UIBlurEffect(style: .dark))
                .inverseMask(RoundedRectangle(cornerRadius: 16.0, style: .circular).padding())
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Please scan QR code.")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 60)
                
                Spacer()
            }
        }
        .alert(item: $alertItem){ alert in
            Alert(title: alert.title,
                  message: alert.message,
                  dismissButton: alert.dismissButton)
            
        }
        .fullScreenCover(isPresented: isAuthPendingUserSelectionBinding) {
            EmployeeList()
        }
    }
}

struct EmployeeList: View {
    @EnvironmentObject var authManager: AuthManager

    class Model: ObservableObject {
        @Published var users: [Restaurant.Employee]?

        var _loadUsersCancellable: AnyCancellable!

        func loadUsers(from authManager: AuthManager) {
            _loadUsersCancellable = authManager.restaurant.loadUsers().sink(receiveCompletion: {
                [unowned self] result in
                self._loadUsersCancellable = nil
                // TODO: handle case .failure(let error) = result...
            }, receiveValue: { [unowned self] users in
                self.users = users
            })
        }
    }
    @StateObject var model = Model()

    @ViewBuilder var noUsersFoundErrorMessage: some View {
        Text("There are no pending users! Please contact your supervisor.")
            .bold()
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        Button(action: {
            authManager.resetAuthState()
        }, label: {
            Text("Retry Scan")
                .frame(width: 250, height: 50, alignment: .center)
                .foregroundColor(.blue)
                .background(Color.white)
                .cornerRadius(10)
        })
        .padding()
    }

    @ViewBuilder func userListing(restaurant: Restaurant, users: [Restaurant.Employee]) -> some View {
        Text("\(restaurant.name)")
            .bold()
            .foregroundColor(Color(UIColor.label))
            .padding(.top, 10)
            .font(.largeTitle)

        List{
            ForEach(users) { user in
                Button(action: {
                    // TODO: Handle potential error that can arise while marking user as inactive.
                    _ = authManager.finishWaiterLogin(withUser: user)
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
        }
        .listStyle(InsetGroupedListStyle())
    }

    var body: some View {
        VStack {
            IfLet(model.users, whenPresent: { users in
                if users.count == 0 {
                    noUsersFoundErrorMessage
                } else {
                    userListing(restaurant: authManager.restaurant, users: users)
                }
            }, whenAbsent: {
                Spinner()
            })
        }
        .onAppear {
            model.loadUsers(from: authManager)
        }
        .navigationBarHidden(true)
    }
}
