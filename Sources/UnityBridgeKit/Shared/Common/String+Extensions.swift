//
//  String+Extensions.swift
//  BootLoaderCore
//
//  Created by Tuan Pham on 06/01/2024.
//

import Foundation

/// String extensions

public extension String {

    /// An "" string.
    static let empty = ""
    
    func toPointer() -> UnsafePointer<CChar>? {
        return NSString(string: self).utf8String
    }
}
