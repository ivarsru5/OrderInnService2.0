//
//  ItemAvailability.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import Combine
import SwiftUI

struct ItemAvailabilityView: View {
    @EnvironmentObject var menuManager: MenuManager
    @State var itemsChangingStatus = Set<MenuItem.FullID>()
    @State var expandedCategories = Set<MenuCategory.ID>()

    func isItemChangingStatus(_ item: MenuItem) -> Bool {
        return itemsChangingStatus.contains(item.fullID)
    }

    func isCategoryExpanded(_ category: MenuCategory) -> Bool {
        return expandedCategories.contains(category.id)
    }

    func expansionBinding(for category: MenuCategory) -> Binding<Bool> {
        Binding(get: {
            return isCategoryExpanded(category)
        }, set: { value in
            if value {
                expandedCategories.insert(category.id)
            } else {
                expandedCategories.remove(category.id)
            }
        })
    }

    func availabilityBinding(for item: MenuItem) -> Binding<Bool> {
        Binding(get: {
            return item.isAvailable
        }, set: { value in
            itemsChangingStatus.insert(item.fullID)
            var sub: AnyCancellable?
            sub = menuManager.update(item: item, setAvailability: value)
                .mapError { error in
                    // TODO[pn 2021-07-16]
                    fatalError("FIXME Failed to update item availability: \(String(describing: error))")
                }
                .sink { _ in
                    itemsChangingStatus.remove(item.fullID)
                    if let _ = sub {
                        sub = nil
                    }
                }
        })
    }

    struct ItemCell: View {
        let item: MenuItem
        let isChangingStatus: Bool
        @Binding var isAvailable: Bool

        var body: some View {
            Button(action: {
                isAvailable.toggle()
            }, label: {
                HStack {
                    Group {
                        Image(systemName: "circle.fill")
                            .symbolSize(10)

                        Text(item.name)
                            .bold()
                    }
                    .foregroundColor(isChangingStatus ? .secondary : .label)

                    Spacer()

                    if isChangingStatus {
                        ActivityIndicator(style: .medium)
                    } else {
                        Text(isAvailable ? "Available" : "Not Available")
                            .bold()
                            .foregroundColor(isAvailable ? .green : .red)
                    }
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(PlainButtonStyle())
        }
    }

    struct CategoryHeader: View {
        var category: MenuCategory
        @Binding var isExpanded: Bool

        var body: some View {
            Button(action: {
                isExpanded.toggle()
            }, label: {
                HStack{
                    Text(category.name)
                        .bold()
                        .foregroundColor(.label)

                    Spacer()

                    Image(systemName: "arrowtriangle.right.fill")
                        .foregroundColor(.label)
                        .symbolSize(20)
                        .rotationEffect(Angle(degrees: isExpanded ? 90 : 0))
                        .animation(.linear(duration: 0.1), value: isExpanded)
                }
                .padding()
            })
            .listRowBackground(Color.secondary)
        }
    }

    var body: some View {
        List {
            ForEach(menuManager.orderedCategories) { category in
                CategoryHeader(category: category,
                               isExpanded: expansionBinding(for: category))

                if isCategoryExpanded(category) {
                    ForEach(menuManager.categoryItems[category.id]!, id: \.self) { itemID in
                        let item = menuManager.menu[itemID]!
                        ItemCell(item: item,
                                 isChangingStatus: isItemChangingStatus(item),
                                 isAvailable: availabilityBinding(for: item))
                    }
                    .padding(.all, 5)
                }
            }
        }
        .navigationTitle("Menu Availability")
    }
}

#if DEBUG
struct ItemAvailabilityView_Previews: PreviewProvider {
    class MenuManagerMock: MenuManager {
        override func update(item: MenuItem, setAvailability isAvailable: Bool) -> AnyPublisher<MenuItem, Error> {
            let updatedItem = MenuItem(id: item.id, name: item.name, price: item.price,
                                       isAvailable: isAvailable, destination: item.destination,
                                       restaurantID: item.restaurantID, categoryID: item.categoryID)

            return Just(updatedItem)
                .delay(for: .seconds(3), scheduler: RunLoop.main, options: .none)
                .map { [unowned self] item in
                    self.menu[item.fullID] = item
                    return item
                }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    typealias ID = MenuItem.FullID

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let categories: MenuManager.Categories = [
        "food": MenuCategory(id: "food", name: "Food", type: .food, restaurantID: restaurant.id),
        "drinks": MenuCategory(id: "drinks", name: "Drinks", type: .drink, restaurantID: restaurant.id),
    ]
    static let menu: MenuManager.Menu = [
        ID(string: "food/1")!: MenuItem(
            id: "1", name: "Food 1", price: 4.99, isAvailable: true,
            destination: .kitchen, restaurantID: restaurant.id, categoryID: "food"),
        ID(string: "food/2")!: MenuItem(
            id: "2", name: "Food 2", price: 4.99, isAvailable: true,
            destination: .kitchen, restaurantID: restaurant.id, categoryID: "food"),
        ID(string: "drinks/1")!: MenuItem(
            id: "1", name: "Drinks 1", price: 4.99, isAvailable: true,
            destination: .bar, restaurantID: restaurant.id, categoryID: "drinks"),
        ID(string: "drinks/2")!: MenuItem(
            id: "2", name: "Drinks 2", price: 4.99, isAvailable: true,
            destination: .bar, restaurantID: restaurant.id, categoryID: "drinks"),
    ]
    static let menuManager = MenuManagerMock(debugForRestaurant: restaurant, withMenu: menu, categories: categories)

    static var previews: some View {
        ItemAvailabilityView()
            .environmentObject(menuManager as MenuManager)
    }
}
#endif
