//
//  CombineExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/12/21.
//

import Foundation
import Combine

/// A dummy error type to use when you need an error type for a generic publisher but the upstream
/// doesn't provide any.
enum DummyError: Error {
    case unexpectedError
}
