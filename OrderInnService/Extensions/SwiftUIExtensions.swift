//
//  SwiftUIExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/9/21.
//

import Foundation
import SwiftUI
import UIKit

extension Color {
    static let label = Color(UIColor.label)
    static let link = Color(UIColor.link)
    static let systemBackground = Color(UIColor.systemBackground)

    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)

    static let gray2 = Color(UIColor.systemGray2)
    static let gray3 = Color(UIColor.systemGray3)
    static let gray4 = Color(UIColor.systemGray4)
    static let gray5 = Color(UIColor.systemGray5)
    static let gray6 = Color(UIColor.systemGray6)
}

// https://stackoverflow.com/a/60203901
// Required as long as base supported version is iOS 14. Swift 5.4 allows
// `if let` in result builders, rendering this unnecessary.
struct IfLet<Value, Content: View, NilContent: View>: View {
    typealias ContentBuilder = (Value) -> Content
    typealias NilContentBuilder = () -> NilContent

    let value: Value?
    let contentBuilder: ContentBuilder
    let nilContentBuilder: NilContentBuilder

    init(
        _ value: Value?,
        @ViewBuilder whenPresent contentBuilder: @escaping ContentBuilder,
        @ViewBuilder whenAbsent nilContentBuilder: @escaping NilContentBuilder
    ) {
        self.value = value
        self.contentBuilder = contentBuilder
        self.nilContentBuilder = nilContentBuilder
    }

    init(_ value: Value?,
         @ViewBuilder whenPresent contentBuilder: @escaping ContentBuilder
    ) where NilContent == EmptyView {
        self.init(value, whenPresent: contentBuilder, whenAbsent: { EmptyView() })
    }

    var body: some View {
        Group {
            if value != nil {
                contentBuilder(value!)
            } else {
                nilContentBuilder()
            }
        }
    }
}

struct BodyFont: ViewModifier {
    let size: CGFloat?
    let weight: Font.Weight?

    init(size: CGFloat? = nil, weight: Font.Weight? = nil) {
        self.size = size
        self.weight = weight
    }

    var font: Font {
        if let size = self.size, let weight = self.weight {
            return Font.system(size: size, weight: weight)
        } else if let size = self.size, self.weight == nil {
            return Font.system(size: size)
        } else if let weight = self.weight, self.size == nil {
            return Font.body.weight(weight)
        } else {
            return Font.body
        }
    }

    func body(content: Content) -> some View {
        return content.font(self.font)
    }
}

extension View {
    func bodyFont(size: CGFloat) -> some View {
        modifier(BodyFont(size: size))
    }
    func bodyFont(weight: Font.Weight) -> some View {
        modifier(BodyFont(weight: weight))
    }
    func bodyFont(size: CGFloat, weight: Font.Weight) -> some View {
        modifier(BodyFont(size: size, weight: weight))
    }
}

enum DismissAction {
    case noop
    case custom(action: () -> ())
    case wrapping(presentationMode: Binding<PresentationMode>)

    @available(iOS 15.0, *)
    init(wrapping dismissAction: SwiftUI.DismissAction) {
        self = .custom(action: dismissAction.callAsFunction)
    }

    func callAsFunction() {
        switch self {
        case .noop: break
        case .custom(let action): action()
        case .wrapping(let presentationMode): presentationMode.wrappedValue.dismiss()
        }
    }
}
struct DismissActionKey: EnvironmentKey {
    static let defaultValue = DismissAction.noop
}
struct IsPresentedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var o6nDismiss: DismissAction {
        get {
            guard case .noop = self[DismissActionKey.self] else {
                return self[DismissActionKey.self]
            }

            if #available(iOS 15.0, *) {
                if self.isPresented {
                    return DismissAction(wrapping: self.dismiss)
                } else {
                    return DismissAction.noop
                }
            } else {
                return DismissAction.wrapping(presentationMode: self.presentationMode)
            }
        }
        set {
            self[DismissActionKey.self] = newValue
        }
    }

    var o6nIsPresented: Bool {
        get {
            var isPresented = self[IsPresentedKey.self]
            if #available(iOS 15.0, *) {
                isPresented = isPresented || self.isPresented
            } else {
                isPresented = isPresented || self.presentationMode.wrappedValue.isPresented
            }
            return isPresented
        }
        set {
            self[IsPresentedKey.self] = newValue
        }
    }
}

struct WhenRendered<Content: View>: View {
    let callback: () -> ()
    let content: () -> Content
    init(call callback: @escaping () -> (), content: @escaping () -> Content) {
        self.callback = callback
        self.content = content
    }

    var body: Content {
        let _ = callback()
        return content()
    }
}
