//
//  MenuView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI
import Combine

struct MenuView: View {
    enum Context {
        case newOrder(table: Table)
        case appendedOrder(part: PendingOrderPart)
    }

    class PendingOrderPart: ObservableObject {
        @Published var entries: [RestaurantOrder.OrderEntry] = []
        weak var menuManager: MenuManager?

        var isEmpty: Bool { entries.isEmpty }

        init(menuManager: MenuManager) {
            self.menuManager = menuManager
        }

        func amount(ofItemWithID itemID: MenuItem.FullID) -> Int {
            if let entry = entries.first(where: { $0.itemID == itemID }) {
                return entry.amount
            } else {
                return 0
            }
        }

        func amountBinding(for itemID: MenuItem.FullID) -> Binding<Int> {
            return Binding(get: { [unowned self] in
                return amount(ofItemWithID: itemID)
            }, set: { [unowned self] value in
                guard value > 0 else {
                    if let index = entries.firstIndex(where: { $0.itemID == itemID }) {
                        entries.remove(at: index)
                    }
                    return
                }

                if let index = entries.firstIndex(where: { $0.itemID == itemID }) {
                    entries[index] = entries[index].with(amount: value)
                } else {
                    let entry = RestaurantOrder.OrderEntry(itemID: itemID, amount: value)
                    entries.append(entry)
                }
            })
        }

        var subtotal: Currency { entries.map { $0.subtotal(using: menuManager!.menu) }.sum() }

        func asOrderPart() -> RestaurantOrder.OrderPart {
            return RestaurantOrder.OrderPart(entries: entries)
        }
    }

    struct AmountSpinner: View {
        @Binding var amount: Int

        var body: some View {
            HStack {
                Button(action: {
                    if amount > 0 {
                        amount -= 1
                    }
                }, label: {
                    Image(systemName: "minus.circle.fill")
                        .symbolSize(30)
                        .foregroundColor(Color.label)
                })
                .buttonStyle(PlainButtonStyle())

                Text(String(amount))
                    .foregroundColor(.secondary)
                    .font(.headline)

                Button(action: {
                    print("[AmountSpinner] Update: \(amount)")
                    amount += 1
                }, label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolSize(30)
                        .foregroundColor(Color.label)
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    struct MenuItemCell: View {
        var item: MenuItem
        @Binding var amount: Int

        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .symbolSize(10)
                    .foregroundColor(Color(UIColor.label))

                Text(item.name)
                    .bold()
                    .foregroundColor(Color(UIColor.label))

                Spacer()

                AmountSpinner(amount: _amount)
            }
            .padding(.leading, 30)
        }
    }

    struct MenuCategoryListing: View {
        let category: MenuCategory
        let items: [MenuItem]
        @ObservedObject var part: PendingOrderPart
        @State var isExpanded = false

        var body: some View {
            Group {
                Button(action: {
                    isExpanded.toggle()
                }, label: {
                    HStack {
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color.label)

                        Spacer()

                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(Color.label)
                            .symbolSize(20)
                            .rotationEffect(Angle(degrees: isExpanded ? 90 : 0))
                            .animation(.linear(duration: 0.1), value: isExpanded)
                    }
                    .padding()
                })
                .listRowBackground(Color.secondary)

                if isExpanded {
                    ForEach(items) { item in
                        MenuItemCell(item: item,
                                     amount: part.amountBinding(for: item.fullID))
                    }
//                    .animation(.linear(duration: 0.1), value: isExpanded)
                }
            }
        }
    }

    struct MenuListing: View {
        let menuManager: MenuManager
        @ObservedObject var part: PendingOrderPart

        private let mealCategories: ArraySlice<MenuCategory>
        private let drinkCategories: ArraySlice<MenuCategory>

        init(menuManager: MenuManager, part: PendingOrderPart) {
            self.menuManager = menuManager
            self._part = ObservedObject(wrappedValue: part)

            let categories = menuManager.orderedCategories
            let firstDrinkIndex = categories.firstIndex(where: { $0.type == .drink })!
            mealCategories = categories.prefix(upTo: firstDrinkIndex)
            drinkCategories = categories.suffix(from: firstDrinkIndex)
        }

        func items(for category: MenuCategory) -> [MenuItem] {
            return menuManager.categoryItems[category.id]!.map { menuManager.menu[$0]! }
        }

        var body: some View {
            List {
                Section(header: Text("Meals")) {
                    ForEach(mealCategories) { category in
                        MenuCategoryListing(category: category,
                                            items: items(for: category),
                                            part: part)
                    }
                }

                Section(header: Text("Drinks")) {
                    ForEach(drinkCategories) { category in
                        MenuCategoryListing(category: category,
                                            items: items(for: category),
                                            part: part)
                    }
                }
            }
        }
    }

    let menuManager: MenuManager
    @StateObject var part: PendingOrderPart

    let context: Context
    @State var alertItem: AlertItem?
    @State var showOrderCart = false

    // HACK[pn 2021-08-02]: Similarly to OrderTabView, there appear to be
    // problems with accessing EnvironmentObjects within init, and given the
    // way Context is implemented, we cannot build a new PendingOrderPart here
    // because MenuManager is not yet available. Therefore we require it to be
    // passed into init from wherever this view is being constructed, similar to
    // OrderTabView.
    init(menuManager: MenuManager, context: Context) {
        self.menuManager = menuManager
        self.context = context

        if case .appendedOrder(part: let part) = context {
            self._part = StateObject(wrappedValue: part)
        } else {
            self._part = StateObject(wrappedValue: PendingOrderPart(menuManager: menuManager))
        }
    }

    #if DEBUG
    init(menuManager: MenuManager, part: PendingOrderPart, context: Context) {
        self.menuManager = menuManager
        self._part = StateObject(wrappedValue: part)
        self.context = context
    }
    #endif

    var table: Table? {
        switch context {
        case .newOrder(table: let table): return table
        case .appendedOrder(part: _): return nil
        }
    }
    
    var body: some View {
        Group {
            MenuListing(menuManager: menuManager, part: part)

            NavigationLink(destination: OrderCartReviewView(part: part), isActive: $showOrderCart) {
                EmptyView()
            }
        }
        .navigationBarTitle("Menu", displayMode: .inline)
        .navigationBarItems(
            trailing: HStack {
                Image(systemName: "cart")

                Text("\(part.subtotal, specifier: "%.2f") EUR")
                    .bold()
            }
            .foregroundColor(part.isEmpty ? Color.secondary : Color.blue)
            .onTapGesture {
                if part.isEmpty {
                    alertItem = UIAlerts.emptyOrder
                } else {
                    showOrderCart = true
                }
            })
        .alert(item: $alertItem) { $0.alert }
    }
}

#if DEBUG
struct MenuView_Previews: PreviewProvider {
    typealias ID = MenuItem.FullID

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let table = Table(id: "T", name: "Table 1", restaurantID: "R", zoneID: "Z")
    static let menuManager = MenuManager(debugForRestaurant: restaurant, withMenu: [
        ID(string: "breakfast/1")!: MenuItem(
            id: "1", name: "Breakfast Pizza", price: 12.34, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "breakfast"),
        ID(string: "breakfast/2")!: MenuItem(
            id: "2", name: "French Toast", price: 13.57, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "breakfast"),
        ID(string: "dinner/1")!: MenuItem(
            id: "1", name: "Dinner Pizza", price: 12.34, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "dinner"),
        ID(string: "dinner/2")!: MenuItem(
            id: "2", name: "Some Spaghetti Or Whatever", price: 13.57, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "dinner"),
        ID(string: "drinks/1")!: MenuItem(
            id: "1", name: "Coffee", price: 4.99, isAvailable: true,
            destination: .bar, restaurantID: "R", categoryID: "drinks"),
        ID(string: "drinks/2")!: MenuItem(
            id: "2", name: "Tea", price: 4.99, isAvailable: true,
            destination: .bar, restaurantID: "R", categoryID: "drinks"),
    ], categories: [
        "breakfast": MenuCategory(id: "breakfast", name: "Breakfast", type: .food, restaurantID: "R"),
        "dinner": MenuCategory(id: "dinner", name: "Dinner", type: .food, restaurantID: "R"),
        "drinks": MenuCategory(id: "drinks", name: "Drinks", type: .drink, restaurantID: "R"),
    ])
    static let part = MenuView.PendingOrderPart(menuManager: menuManager)

    struct Wrapper: View {
        @EnvironmentObject var menuManager: MenuManager
        @ObservedObject var part: MenuView.PendingOrderPart

        var body: some View {
            VStack {
                MenuView(menuManager: menuManager,
                         part: part,
                         context: .appendedOrder(part: part))

                HStack {
                    Text("(DEBUG) Total:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("EUR \(part.subtotal, specifier: "%.2f")")
                        .bold()
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        Group {
            Wrapper(part: part)
                .preferredColorScheme(.light)
            Wrapper(part: part)
                .preferredColorScheme(.dark)

            NavigationView {
                MenuView(menuManager: menuManager,
                         part: part,
                         context: .newOrder(table: table))
            }
        }
        .environmentObject(menuManager)
    }
}
#endif
