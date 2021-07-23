//
//  ItemAvailability.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import Combine
import SwiftUI

struct ItemAvailability: View {
    @StateObject var availabilityController = ItemAvailabilityController()
    @State var itemsChangingStatus = Set<MenuItem.ID>()
    @State var expandedCategories = Set<MenuCategory.ID>()

    func isItemChangingStatus(_ item: MenuItem) -> Bool {
        return itemsChangingStatus.contains(item.id)
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
            itemsChangingStatus.insert(item.id)
            var sub: AnyCancellable?
            sub = availabilityController.setAvailable(value, for: item)
                .catch { error in
                    // TODO[pn 2021-07-16]: Handle error
                    return Empty().setFailureType(to: Never.self)
                }
                .sink(receiveValue: { item in
                    itemsChangingStatus.remove(item.id)
                    if let _ = sub {
                        sub = nil
                    }
                })
        })
    }

    struct ItemCell: View {
        var item: MenuItem
        var isChangingStatus: Bool
        @Binding var isAvailable: Bool

        var body: some View {
            Button(action: {
                isAvailable.toggle()
            }, label: {
                HStack {
                    Image(systemName: "circle.fill")
                        .symbolSize(10)
                        .foregroundColor(Color.label)

                    Text(item.name)
                        .bold()
                        .foregroundColor(Color.label)

                    Spacer()

                    Text(isAvailable ? "Is Available" : "Not Available")
                        .bold()
                        .foregroundColor(isAvailable ? Color.green : Color.red)
                }
                .opacity(isChangingStatus ? 0.7 : 1.0)
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
        }
    }

    var body: some View {
        List {
            ForEach(availabilityController.menuCategories, id: \.id) { category in
                CategoryHeader(category: category,
                               isExpanded: expansionBinding(for: category))

                if isCategoryExpanded(category) {
                    ForEach(availabilityController.categoryItems[category.id]!, id: \.id) { item in
                        ItemCell(item: item,
                                 isChangingStatus: isItemChangingStatus(item),
                                 isAvailable: availabilityBinding(for: item))
                    }
                    .padding(.all, 5)
                }
            }
        }
        .navigationTitle("Menu Availability")
        .onAppear {
            availabilityController.getMenuCategory()
        }
    }
}
