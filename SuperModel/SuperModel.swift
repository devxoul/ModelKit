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

public func == (lhs: SuperEnum.Type, rhs: SuperEnum.Type) -> Bool {
    return toString(lhs) == toString(rhs)
}

public protocol SuperEnum {
    var rawValue: Int { get }
    func fromInt(int: Int) -> Self
}

public protocol StringEnum: SuperEnum {
    var stringValue: String { get }
    func fromString(string: String) -> Self
}


internal class Property: Printable {
    var name: String!
    var type: Any.Type!
    var defaultValue: Any?

    var isOptional: Bool = false
    var isArray: Bool {
        return self.typeDescription.hasPrefix("Array<")
    }

    var typeDescription: String {
        var description = toString(self.type).stringByReplacingOccurrencesOfString(
            "Swift.",
            withString: "",
            options: .allZeros,
            range: nil
        )
        if self.isOptional {
            let start = advance(description.startIndex, "Optional<".length)
            let end = advance(description.endIndex, -1 * ">".length)
            let range = Range<String.Index>(start: start, end: end)
            description = description.substringWithRange(range) + "?"
        }
        return description
    }

    var modelClass: SuperModel.Type? {
        var className = self.typeDescription
        if self.isOptional {
            className = className.substringToIndex(advance(className.endIndex, -1))
        }
        if self.isArray {
            let start = advance(className.startIndex, "Array<".length)
            let end = advance(className.endIndex, -1 * ">".length)
            let range = Range<String.Index>(start: start, end: end)
            className = className.substringWithRange(range)
        }
        return NSClassFromString(className) as? SuperModel.Type
    }

    var description: String {
        return "@property \(self.name): \(self.typeDescription)"
    }
}


public class SuperModel: NSObject {

    public class func dateFormatterForKey(key: String) -> NSDateFormatter? {
        return self.defaultDateFormatter
    }


    internal var properties: [Property] {
        if let cachedProperties = self.dynamicType.cachedProperties {
            return cachedProperties
        }

        let mirror = reflect(self)
        if mirror.count <= 1 {
            return [Property]()
        }

        var properties = [Property]()
        for i in 1..<mirror.count {
            let (name, propertyMirror) = mirror[i]

            let property = Property()
            property.name = name
            if toString(propertyMirror.valueType) == "__NSCFNumber" {
                property.type = NSNumber.self
            } else {
                property.type = propertyMirror.valueType
            }
            property.defaultValue = propertyMirror.value
            property.isOptional = propertyMirror.disposition == .Optional
            properties.append(property)
        }

        self.dynamicType.cachedProperties = properties
        return properties
    }

    internal class var cachedProperties: [Property]? {
        get {
            return objc_getAssociatedObject(self, "properties") as? [Property]
        }
        set {
            objc_setAssociatedObject(
                self,
                "properties",
                newValue,
                objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            )
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
        if let property = self.properties.filter({ $0.name == key }).first {
            if value == nil {
                super.setValue(value, forKey: key)
                return
            }

            let type = property.type

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

            else if type == NSDate.self || type == Optional<NSDate>.self {
                let formatter = self.dynamicType.dateFormatterForKey(key) ?? SuperModel.defaultDateFormatter
                if let date = formatter.dateFromString(value as! String) {
                    super.setValue(date, forKey: key)
                }
            }

            // List
            else if let modelClass = property.modelClass where property.isArray {
                if let array = value as? [Dict] {
                    let models = modelClass.fromList(array)
                    super.setValue(models, forKey: key)
                }
            }

            // Relationship
            else if let modelClass = property.modelClass {
                if let dict = value as? Dict {
                    let model = modelClass.init(dict)
                    super.setValue(model, forKey: key)
                }
            }

            // String Enum
            else if let defaultValue = property.defaultValue as? StringEnum,
                        stringValue = (value as? String) ?? (value as? NSNumber)?.stringValue {
                let enumValue = defaultValue.fromString(value as! String)
                super.setValue(enumValue.rawValue, forKey: key)
            }

            // Integer Enum
            else if let enumType = property.type as? SuperEnum.Type {
                if let rawValue = value as? NSNumber {
                    super.setValue(rawValue, forKey: key)
                } else if let string = value as? String, rawValue = self.dynamicType.numberFromString(string) {
                    super.setValue(rawValue, forKey: key)
                }
            }

            // What else?
            else {
                println("Else: \(key): \(type) = \(value)")
            }
        }
    }

    public func toDictionary(nulls: Bool = false) -> Dict {
        var dictionary = Dict()
        for property in self.properties {
            if let value: AnyObject = self.valueForKey(property.name) {

                // Model
                if let model = value as? SuperModel {
                    dictionary[property.name] = model.toDictionary(nulls: nulls)
                }

                // List
                else if let models = value as? [SuperModel] {
                    dictionary[property.name] = models.map { $0.toDictionary(nulls: nulls) }
                }

                // Date
                else if let date = value as? NSDate {
                    let formatter = self.dynamicType.dateFormatterForKey(property.name)
                        ?? SuperModel.defaultDateFormatter
                    dictionary[property.name] = formatter.stringFromDate(date)
                }

                // String Enum
                else if let defaultValue = property.defaultValue as? StringEnum {
                    dictionary[property.name] = defaultValue.fromInt(value as! Int).stringValue
                }

                // Integer Enum
                else if let enumValue = value as? SuperEnum {
                    dictionary[property.name] = enumValue.rawValue
                }

                // Primitive Types
                else {
                    dictionary[property.name] = value as? NSObject
                }
            } else if nulls {
                dictionary[property.name] = NSNull()
            }
        }
        return dictionary
    }

    private struct Shared {
        static let numberFormatter = NSNumberFormatter()
        static let dateFormatter = NSDateFormatter()
    }

    public class func numberFromString(string: String) -> Number? {
        let formatter = Shared.numberFormatter
        if formatter.numberStyle != .DecimalStyle {
            formatter.numberStyle = .DecimalStyle
        }
        return formatter.numberFromString(string)
    }

    public static let defaultDateFormatter: NSDateFormatter = Shared.dateFormatter

}
