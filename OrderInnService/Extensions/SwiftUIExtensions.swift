//
//  SwiftUIExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/9/21.
//

import Foundation
import SwiftUI

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

extension Binding {
    init(readOnly `get`: @escaping () -> Value) {
        self.init(get: `get`, set: { _ in fatalError("Tried to set read-only binding") })
    }
}
