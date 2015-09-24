//
//  Property.swift
//  ModelKit
//
//  Created by 전수열 on 9/24/15.
//  Copyright © 2015 Suyeol Jeon. All rights reserved.
//

internal struct Property: CustomStringConvertible {

    var name: String
    var type: Any.Type
    var displayStyle: Mirror.DisplayStyle?
    var defaultValue: Any

    var description: String {
        return "\(self.name): \(self.type)"
    }
    
}
