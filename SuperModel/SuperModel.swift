// The MIT License (MIT)
//
// Copyright (c) 2015 Suyeol Jeon (xoul.kr)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation


public typealias Number = NSNumber
public typealias Dict = [NSObject: AnyObject]


public func == (lhs: Any.Type, rhs: Any.Type) -> Bool {
    return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
}


internal struct Property: Printable {
    var name: String
    var type: Any.Type

    var description: String {
        var description = "\(self.name): \(self.type)".stringByReplacingOccurrencesOfString(
            "Swift.",
            withString: "",
            options: .allZeros,
            range: nil
        )
        return description
    }
}

typealias PropertyList = [String: Any.Type]

public class SuperModel: NSObject {

    internal var properties: PropertyList {
        if let cachedProperties = self.dynamicType.cachedProperties {
            return cachedProperties
        }

        let mirror = reflect(self)
        if mirror.count <= 1 {
            return PropertyList()
        }

        var properties = PropertyList()
        for i in 1..<mirror.count {
            let (name, property) = mirror[i]
            let type = property.valueType
            properties[name] = type
        }

        self.dynamicType.cachedProperties = properties
        return properties
    }

    internal class var cachedProperties: PropertyList? {
        get { return objc_getAssociatedObject(self, "properties") as? PropertyList }
        set {
            let policy = objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, "properties", newValue as? AnyObject, policy)
        }
    }

    public convenience init(_ dictionary: Dict) {
        self.init()

        for (key, value) in dictionary {
            if key is String == false {
                continue
            }

            let key = key as! String
            let type = self.properties[key]!

            // String
            if let value = value as? String where (type == String.self || type == Optional<String>.self) {
                self.setValue(value, forKey: key)
            }

            // Number
            else if let value = value as? Number where (type == Number.self || type == Optional<Number>.self) {
                self.setValue(value, forKey: key)
            }

            // What else?
            else {
                println("key, value, type")
            }
        }
    }

}
