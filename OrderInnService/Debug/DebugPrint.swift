//
//  DebugPrint.swift
//  OrderInnService
//
//  Created by paulsnar on 8/17/21.
//

import Foundation

/// Print a message, prefixed with `~[` for simpler filtering in the debug output.
func debug_print(_ component: String, _ message: String) {
    print("~[\(component)][\(Date())] \(message)")
}
