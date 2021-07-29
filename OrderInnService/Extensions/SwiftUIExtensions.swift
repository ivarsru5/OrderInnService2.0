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
struct IfLet<Value, Content, NilContent>: View where Content: View, NilContent: View {
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

extension IfLet where NilContent == EmptyView {
    init(_ value: Value?, @ViewBuilder whenPresent contentBuilder: @escaping ContentBuilder) {
        self.init(value, whenPresent: contentBuilder, whenAbsent: { EmptyView() })
    }
}

struct SymbolSize: ViewModifier {
    let size: CGFloat

    init(_ size: CGFloat) {
        self.size = size
    }

    func body(content: Content) -> some View {
        return content
            .font(Font.custom("SF Symbols", size: size))
    }
}

extension View {
    func symbolSize(_ size: CGFloat) -> some View {
        return self.modifier(SymbolSize(size))
    }
}

