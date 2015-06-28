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


public func == (lhs: Any.Type, rhs: Any.Type) -> Bool {
    return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
}

public func == (lhs: SuperEnum.Type, rhs: SuperEnum.Type) -> Bool {
    return toString(lhs) == toString(rhs)
}

public protocol SuperEnum {
    var rawValue: Int { get }
}

public protocol StringEnum: SuperEnum {
    var rawValues: [Int: String?] { get }
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

    public class func keyPathForKeys() -> [String: String]? {
        return nil
    }

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

    public class func propertySetterNameForKey(key: String) -> String {
        if isEmpty(key) {
            return key
        }
        let range = key.startIndex..<advance(key.startIndex, 1)
        let uppercase = key.substringWithRange(range).uppercaseString
        let name = "set" + key.stringByReplacingCharactersInRange(range, withString: uppercase) + ":"
        return name
    }


    public class func fromArray(array: AnyObject?) -> [SuperModel] {
        if let array = array as? [[String: NSObject]] {
            return array.map { self.init($0) }
        }
        return []
    }

    public convenience init(_ dictionary: AnyObject) {
        self.init()
        self.update(dictionary)
    }

    public func update(dictionary: AnyObject) {
        if let dictionary = dictionary as? [String: NSObject] {
            self.setValuesForKeysWithDictionary(dictionary)
        }
    }

    public override func setValuesForKeysWithDictionary(keyedValues: [NSObject : AnyObject]) {
        for (key, value) in keyedValues {
            if let key = key as? String {
                self.setValue(value, forKey: key)

                if let keyPaths = self.dynamicType.keyPathForKeys() {
                    for (property, keyPath) in keyPaths {
                        if keyPath == key && property != keyPath {
                            self.setValue(value, forKey: property)
                        }

                        else if keyPath.hasPrefix(key + ".") {
                            var dictKeys = keyPath.componentsSeparatedByString(".")
                            dictKeys.removeAtIndex(0)

                            var valueForKeyPath: AnyObject? = value
                            while count(dictKeys) > 0 {
                                let newValue: AnyObject? = valueForKeyPath?[dictKeys.first!]
                                if newValue == nil {
                                    break
                                }
                                valueForKeyPath = newValue
                                dictKeys.removeAtIndex(0)
                            }

                            self.setValue(valueForKeyPath, forKey: property)
                        }
                    } // end for
                } // end if-let keyPaths
            } // end if-let key
        }
    }

    public override func setValue(value: AnyObject?, forKey key: String) {
        if let property = self.properties.filter({ $0.name == key }).first {
            let type = property.type

            // if model doesn't have setter method for key
            if !self.respondsToSelector(Selector(self.dynamicType.propertySetterNameForKey(key))) {

                // if model doesn't have ivar - it's undefined key
                let ivar = class_getInstanceVariable(self.dynamicType, key)
                if ivar.hashValue == 0 {
                    return self.setValue(value, forUndefinedKey: key)
                }

                // memory address for ivar
                let address = ObjectIdentifier(self).uintValue + UInt(ivar_getOffset(ivar))

                if type == Int.self || type == Optional<Int>.self {
                    let pointer = UnsafeMutablePointer<Int?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.integerValue
                    return
                }

                if type == Int8.self || type == Optional<Int8>.self {
                    let pointer = UnsafeMutablePointer<Int8?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.charValue
                    return
                }

                if type == Int16.self || type == Optional<Int16>.self {
                    let pointer = UnsafeMutablePointer<Int16?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.shortValue
                    return
                }

                if type == Int32.self || type == Optional<Int32>.self {
                    let pointer = UnsafeMutablePointer<Int32?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.intValue
                    return
                }

                if type == Int64.self || type == Optional<Int64>.self {
                    let pointer = UnsafeMutablePointer<Int64?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.longLongValue
                    return
                }

                if type == UInt.self || type == Optional<UInt>.self {
                    let pointer = UnsafeMutablePointer<UInt?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.unsignedLongValue
                    return
                }

                if type == UInt8.self || type == Optional<UInt8>.self {
                    let pointer = UnsafeMutablePointer<UInt8?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.unsignedCharValue
                    return
                }

                if type == UInt16.self || type == Optional<UInt16>.self {
                    let pointer = UnsafeMutablePointer<UInt16?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.unsignedShortValue
                    return
                }
                
                if type == UInt32.self || type == Optional<UInt32>.self {
                    let pointer = UnsafeMutablePointer<UInt32?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.unsignedIntValue
                    return
                }
                
                if type == UInt64.self || type == Optional<UInt64>.self {
                    let pointer = UnsafeMutablePointer<UInt64?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.unsignedLongLongValue
                    return
                }

                if type == Float.self || type == Optional<Float>.self {
                    let pointer = UnsafeMutablePointer<Float?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.floatValue
                    return
                }

                if type == Double.self || type == Optional<Double>.self {
                    let pointer = UnsafeMutablePointer<Double?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.doubleValue
                    return
                }

                if type == CGFloat.self || type == Optional<CGFloat>.self {
                    let pointer = UnsafeMutablePointer<CGFloat?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value) as? CGFloat
                    return
                }

                if type == Bool.self || type == Optional<Bool>.self {
                    let pointer = UnsafeMutablePointer<Bool?>(bitPattern: address)
                    pointer.memory = self.dynamicType.numberFromValue(value)?.boolValue
                    return
                }
            }

            // String
            if type == String.self || type == Optional<String>.self {
                if let value = value as? String {
                    super.setValue(value, forKey: key)
                } else if let value = value as? NSNumber {
                    super.setValue(value.stringValue, forKey: key)
                }
            }

            // Number
            else if type == NSNumber.self || type == Optional<NSNumber>.self {
                super.setValue(self.dynamicType.numberFromValue(value), forKey: key)
            }

            // Date
            else if type == NSDate.self || type == Optional<NSDate>.self || toString(type) == "__NSDate" {
                let formatter = self.dynamicType.dateFormatterForKey(key) ?? SuperModel.defaultDateFormatter
                if let stringValue = value as? String, date = formatter.dateFromString(stringValue) {
                    super.setValue(date, forKey: key)
                }
            }

            // URL
            else if type == NSURL.self || type == Optional<NSURL>.self {
                if let URLString = value as? String, URL = NSURL(string: URLString) {
                    super.setValue(URL, forKey: key)
                }
            }

            // List
            else if let modelClass = property.modelClass where property.isArray {
                if let array = value as? [[String: NSObject]] {
                    let models = modelClass.fromArray(array)
                    super.setValue(models, forKey: key)
                }
            }

            // Relationship
            else if let modelClass = property.modelClass {
                if let dict = value as? [String: NSObject] {
                    let model = modelClass.init(dict)
                    super.setValue(model, forKey: key)
                }
            }

            // String Enum
            else if let defaultValue = property.defaultValue as? StringEnum,
                        stringValue = (value as? String) ?? (value as? NSNumber)?.stringValue {
                for (raw, string) in defaultValue.rawValues {
                    if string == stringValue {
                        super.setValue(raw, forKey: key)
                        break
                    }
                }
            }

            // Integer Enum
            else if let enumType = property.type as? SuperEnum.Type {
                super.setValue(self.dynamicType.numberFromValue(value), forKey: key)
            }

            // What else?
            else {
                println("Else: \(key): \(type) = \(value)")
            }
        }
    }

    override public func setValue(value: AnyObject?, forUndefinedKey key: String) {
        // implement in subclass if needed
    }

    override public func valueForKey(key: String) -> AnyObject? {
        if !self.respondsToSelector(Selector(key)) {
            let ivar = class_getInstanceVariable(self.dynamicType, key)
            if let type = self.properties.filter({ $0.name == key }).first?.type where ivar.hashValue != 0 {
                let address = ObjectIdentifier(self).uintValue + UInt(ivar_getOffset(ivar))

                if type == Int.self || type == Optional<Int>.self {
                    let pointer = UnsafeMutablePointer<Int?>(bitPattern: address)
                    return pointer.memory
                }

                if type == Int8.self || type == Optional<Int8>.self {
                    let pointer = UnsafeMutablePointer<Int8?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == Int16.self || type == Optional<Int16>.self {
                    let pointer = UnsafeMutablePointer<Int16?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == Int32.self || type == Optional<Int32>.self {
                    let pointer = UnsafeMutablePointer<Int32?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == Int64.self || type == Optional<Int64>.self {
                    let pointer = UnsafeMutablePointer<Int64?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == UInt.self || type == Optional<UInt>.self {
                    let pointer = UnsafeMutablePointer<UInt?>(bitPattern: address)
                    return pointer.memory
                }

                if type == UInt8.self || type == Optional<UInt8>.self {
                    let pointer = UnsafeMutablePointer<UInt8?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == UInt16.self || type == Optional<UInt16>.self {
                    let pointer = UnsafeMutablePointer<UInt16?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == UInt32.self || type == Optional<UInt32>.self {
                    let pointer = UnsafeMutablePointer<UInt32?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == UInt64.self || type == Optional<UInt64>.self {
                    let pointer = UnsafeMutablePointer<UInt64?>(bitPattern: address)
                    return pointer.memory as? AnyObject
                }

                if type == Float.self || type == Optional<Float>.self {
                    let pointer = UnsafeMutablePointer<Float?>(bitPattern: address)
                    return pointer.memory
                }

                if type == Double.self || type == Optional<Double>.self {
                    let pointer = UnsafeMutablePointer<Double?>(bitPattern: address)
                    return pointer.memory
                }

                if type == CGFloat.self || type == Optional<CGFloat>.self {
                    let pointer = UnsafeMutablePointer<CGFloat?>(bitPattern: address)
                    return pointer.memory
                }

                if type == Bool.self || type == Optional<Bool>.self {
                    let pointer = UnsafeMutablePointer<Bool?>(bitPattern: address)
                    return pointer.memory
                }
            }
        }
        return super.valueForKey(key)
    }

    public func toDictionary(nulls: Bool = false) -> [String: NSObject] {
        var dictionary = [String: NSObject]()
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

                // URL
                else if let URL = value as? NSURL {
                    dictionary[property.name] = URL.absoluteString
                }

                // String Enum
                else if let defaultValue = property.defaultValue as? StringEnum {
                    for (raw, string) in defaultValue.rawValues {
                        if raw == value as! Int {
                            dictionary[property.name] = string
                            break
                        }
                    }
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

    public class func arrayFromModels(models: [SuperModel]) -> [[String: NSObject]] {
        return models.map { $0.toDictionary() }
    }

    private struct Shared {
        static let numberFormatter = NSNumberFormatter()
        static let dateFormatter = NSDateFormatter()
    }

    public class func numberFromValue(value: AnyObject?) -> NSNumber? {
        if let value = value as? NSNumber {
            return value
        }
        if let string = value as? String {
            Shared.numberFormatter.numberStyle = .DecimalStyle
            return Shared.numberFormatter.numberFromString(string)
        }
        return nil
    }

    public static let defaultDateFormatter: NSDateFormatter = Shared.dateFormatter
}
