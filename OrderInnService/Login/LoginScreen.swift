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
    @State var alertTemplate: Alerts.Template?

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
        GeometryReader { proxy in
            ZStack {
                QRScannerView(alertTemplate: $alertTemplate)

                let maskSize = proxy.size.width * 0.8
                let mask = RoundedRectangle(cornerRadius: 16.0, style: .circular)
                    .size(width: maskSize, height: maskSize)
                    .padding(EdgeInsets(top: (proxy.size.height - maskSize) / 2,
                                        leading: (proxy.size.width - maskSize) / 2,
                                        bottom: (proxy.size.height - maskSize) / 2,
                                        trailing: (proxy.size.width - maskSize) / 2))
                BlurEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inverseMask(mask)

                Text("Please scan QR code.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, proxy.size.height * 0.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(template: $alertTemplate)
        .fullScreenCover(isPresented: isAuthPendingUserSelectionBinding) {
            EmployeeList()
        }
    }
}

struct EmployeeList: View {
    @EnvironmentObject var authManager: AuthManager

    class Model: ObservableObject {
        @Published var users: [Restaurant.Employee]?

        func loadUsers(from authManager: AuthManager) {
            var sub: AnyCancellable?
            sub = authManager.restaurant.firestoreReference
                .collection(of: Restaurant.Employee.self)
                .get()
                .mapError { error in
                    // TODO[pn 2021-08-03]
                    fatalError("FIXME Failed to load waiter list: \(String(describing: error))")
                }
                .collect()
                .sink { [unowned self] users in
                    self.users = users
                    if let _ = sub {
                        sub = nil
                    }
                }
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
                    var sub: AnyCancellable?
                    sub = authManager.finishWaiterLogin(withUser: user)
                        .mapError { error in
                            // TODO[pn 2021-08-03]
                            fatalError("FIXME Failed to finish login: \(String(describing: error))")
                        }
                        .sink { _ in
                            if let _ = sub {
                                sub = nil
                            }
                        }
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
            if model.users == nil {
                model.loadUsers(from: authManager)
            }
        }
        .navigationBarHidden(true)
    }
}
