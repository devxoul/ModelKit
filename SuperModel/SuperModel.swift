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
public typealias Dict = [String: NSObject]


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

    public class func fromList(list: [Dict]) -> [SuperModel] {
        return list.map { self.init($0) }
    }

    public convenience init(_ dictionary: Dict) {
        self.init()
        self.update(dictionary)
    }

    public func update(dictionary: Dict) {
        self.setValuesForKeysWithDictionary(dictionary)
    }

    public override func setValue(value: AnyObject?, forKey key: String) {
        if let type = self.properties[key] { // which type property declared as

            // String
            if type == String.self || type == Optional<String>.self {
                if let value = value as? String {
                    super.setValue(value, forKey: key)
                } else if let value = value as? Number {
                    super.setValue(value.stringValue, forKey: key)
                }
            }

            // Number
            else if type == Number.self || type == Optional<Number>.self {
                if let value = value as? Number {
                    super.setValue(value, forKey: key)
                } else if let value = value as? String, number = self.dynamicType.numberFromString(value) {
                    super.setValue(number, forKey: key)
                }
            }

            // What else?
            else {
                println("Else: \(key): \(type) = \(value)")
            }
        } else {
            super.setValue(value, forKey: key)
        }
    }

    public func toDictionary(nulls: Bool = false) -> Dict {
        var dictionary = Dict()
        for name in self.properties.keys {
            if let value: AnyObject = self.valueForKey(name) {
                dictionary[name] = value as? NSObject
            } else if nulls {
                dictionary[name] = NSNull()
            }
        }
        return dictionary
    }

    private struct Shared {
        static let numberFormatter = NSNumberFormatter()
    }

    public class func numberFromString(string: String) -> Number? {
        let formatter = Shared.numberFormatter
        if formatter.numberStyle != .DecimalStyle {
            formatter.numberStyle = .DecimalStyle
        }
        return formatter.numberFromString(string)
    }

}
