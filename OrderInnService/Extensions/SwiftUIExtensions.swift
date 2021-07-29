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

struct O6NButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.bold())
            .foregroundColor(.systemBackground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.label)
            .cornerRadius(16)
            .padding(16)
    }
}
