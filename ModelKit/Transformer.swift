//
//  Transformer.swift
//  ModelKit
//
//  Created by 전수열 on 9/24/15.
//  Copyright © 2015 Suyeol Jeon. All rights reserved.
//

import Foundation

public class Transformer<T> {

    public typealias Block = (Any? -> T?)
    public typealias ReverseBlock = (T? -> Any?)

    public var block: Block?
    public var reverseBlock: ReverseBlock?

    public init(block: Block? = nil, reverseBlock: ReverseBlock? = nil) {
        self.block = block
        self.reverseBlock = reverseBlock
    }

    public func transformedValue(value: Any?) -> T? {
        return self.block?(value)
    }

    public func reverseTransformedValue(value: T?) -> Any? {
        return self.reverseBlock?(value)
    }

}


public let URLTransformer = Transformer<NSURL>(
    block: { value in
        return (value as? String).flatMap { NSURL(string: $0) }
    },
    reverseBlock: { URL in
        return URL?.absoluteString
    }
)
