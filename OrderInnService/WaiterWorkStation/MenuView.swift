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
        var menu: MenuItem.Menu = [:]

        var isEmpty: Bool { entries.isEmpty }

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

        var subtotal: Currency { entries.map { $0.subtotal(using: menu) }.sum() }

        func asOrderPart() -> RestaurantOrder.OrderPart {
            return RestaurantOrder.OrderPart(entries: entries)
        }
    }

    class Model: ObservableObject {
        @Published var categories: [MenuCategory] = []
        @Published var itemsInCategories: [MenuCategory.ID: [MenuItem]] = [:]
        @Published var menu: MenuItem.Menu = [:]
        @Published var isLoading = true

        var sub: AnyCancellable?
        func loadCategoriesAndItems(_ part: PendingOrderPart) {
            sub = AuthManager.shared.restaurant.firestoreReference
                .collection(of: MenuCategory.self)
                .get()
                .catch { error in
                    // TODO[pn 2021-07-16]
                    return Empty().setFailureType(to: Never.self)
                }
                .flatMap { [unowned self] category -> AnyPublisher<(MenuCategory, [MenuItem]), Error> in
                    categories.append(category)

                    let items = category.firestoreReference
                        .collection(of: MenuItem.self)
                        .get()
                        .collect()
                    return Just(category)
                        .setFailureType(to: Error.self)
                        .zip(items)
                        .eraseToAnyPublisher()
                }
                .catch { error in
                    // TODO[pn 2021-07-16]
                    return Empty().setFailureType(to: Never.self)
                }
                .sink(receiveCompletion: { [unowned self] _ in
                    reorderCategories()
                    part.menu = menu
                    isLoading = false
                }, receiveValue: { [unowned self] tuple in
                    let (category, items) = tuple
                    itemsInCategories[category.id] = items
                    items.forEach { item in
                        menu[item.fullID] = item
                    }
                })
        }

        private func reorderCategories() {
            var mealCategories = [MenuCategory]()
            var drinkCategories = [MenuCategory]()

            categories.forEach { category in
                switch category.type {
                case .food: mealCategories.append(category)
                case .drink: drinkCategories.append(category)
                }
            }
            mealCategories.sort(by: { $0.id < $1.id })
            drinkCategories.sort(by: { $0.id < $1.id })
            categories.removeAll(keepingCapacity: true)
            categories.append(contentsOf: mealCategories)
            categories.append(contentsOf: drinkCategories)
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
        let categories: [MenuCategory]
        let items: [MenuCategory.ID: [MenuItem]]
        let part: PendingOrderPart

        private let mealCategories: ArraySlice<MenuCategory>
        private let drinkCategories: ArraySlice<MenuCategory>

        init(categories: [MenuCategory],
             items: [MenuCategory.ID: [MenuItem]],
             part: PendingOrderPart) {
            self.categories = categories
            self.items = items
            self.part = part

            let firstDrinkIndex = categories.firstIndex(where: { $0.type == .drink })!
            mealCategories = categories.prefix(upTo: firstDrinkIndex)
            drinkCategories = categories.suffix(from: firstDrinkIndex)
        }

        var body: some View {
            List {
                Section(header: Text("Meals")) {
                    ForEach(mealCategories) { category in
                        MenuCategoryListing(category: category,
                                            items: items[category.id]!,
                                            part: part)
                    }
                }

                Section(header: Text("Drinks")) {
                    ForEach(drinkCategories) { category in
                        MenuCategoryListing(category: category,
                                            items: items[category.id]!,
                                            part: part)
                    }
                }
            }
        }
    }

    @StateObject var part: PendingOrderPart
    @StateObject var model = Model()

    let context: Context
    @State var alertItem: AlertItem?
    @State var showOrderCart = false

    init(context: Context) {
        self.context = context
        if case .appendedOrder(part: let part) = context {
            self._part = StateObject(wrappedValue: part)
        } else {
            self._part = StateObject(wrappedValue: PendingOrderPart())
        }
    }

    #if DEBUG
    init(part: PendingOrderPart, model: Model, context: Context) {
        self._part = StateObject(wrappedValue: part)
        self._model = StateObject(wrappedValue: model)
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
            if model.isLoading {
                Spinner()
            } else {
                MenuListing(categories: model.categories,
                            items: model.itemsInCategories,
                            part: part)
            }

            NavigationLink(destination: OrderCartReviewView(part: part, menu: $model.menu), isActive: $showOrderCart) {
                EmptyView()
            }
        }
        .onAppear {
            if model.isLoading {
                model.loadCategoriesAndItems(part)
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
    static let model = MenuView.Model()
    static func prepareModel() {
        guard model.isLoading else { return }

        model.isLoading = false
        model.categories = [
            MenuCategory(id: "breakfast", name: "Breakfast", type: .food, restaurantID: "R"),
            MenuCategory(id: "dinner", name: "Dinner", type: .food, restaurantID: "R"),
            MenuCategory(id: "drinks", name: "Drinks", type: .drink, restaurantID: "R"),
        ]
        model.itemsInCategories = [
            "breakfast": [
                MenuItem(id: "breakfast.1", name: "Breakfast Pizza", price: 12.34,
                         isAvailable: true, destination: .kitchen, restaurantID: "R",
                         categoryID: "breakfast"),
                MenuItem(id: "breakfast.2", name: "French Toast", price: 13.57,
                         isAvailable: true, destination: .kitchen, restaurantID: "R",
                         categoryID: "breakfast"),
            ],
            "dinner": [
                MenuItem(id: "dinner.1", name: "Dinner Pizza", price: 12.34,
                         isAvailable: true, destination: .kitchen, restaurantID: "R",
                         categoryID: "dinner"),
                MenuItem(id: "dinner.2", name: "Some Spaghetti Or Whatever", price: 13.57,
                         isAvailable: true, destination: .kitchen, restaurantID: "R",
                         categoryID: "dinner"),
            ],
            "drinks": [
                MenuItem(id: "drinks.1", name: "Coffee", price: 4.99,
                         isAvailable: true, destination: .bar, restaurantID: "R",
                         categoryID: "drinks"),
                MenuItem(id: "drinks.2", name: "Tea", price: 4.99,
                         isAvailable: true, destination: .bar, restaurantID: "R",
                         categoryID: "drinks"),
            ],
        ]
    }

    static let table = Table(id: "T", name: "Table 1", restaurantID: "R", zoneID: "Z")

    static let part = MenuView.PendingOrderPart()

    struct Wrapper: View {
        @ObservedObject var part: MenuView.PendingOrderPart
        let model: MenuView.Model
        let table: Table

        var body: some View {
            VStack {
                MenuView(part: part, model: model,
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
        let _ = prepareModel()

        Wrapper(part: part, model: model, table: table)
            .preferredColorScheme(.light)
        Wrapper(part: part, model: model, table: table)
            .preferredColorScheme(.dark)

        NavigationView {
            MenuView(part: part, model: model,
                     context: .newOrder(table: table))
        }
    }
}
#endif
