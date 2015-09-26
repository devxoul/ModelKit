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

public class Model {

    // MARK: Properties

    private static var _cachedProperties = [String: [String: Property]]()
    internal class var properties: [String: Property] {
        let modelName = String(self)
        if self._cachedProperties[modelName] == nil {
            self._cachedProperties[modelName] = [:]
            for child in Mirror(reflecting: self.init()).children {
                if let label = child.label {
                    let mirror = Mirror(reflecting: child.value)
                    let displayStyle = mirror.displayStyle.flatMap { Mirror(reflecting: $0).displayStyle }
                    let property = Property(name: label, type: mirror.subjectType, displayStyle: displayStyle, defaultValue: child.value)
                    self._cachedProperties[modelName]![label] = property
                }
            }
        }
        return self._cachedProperties[modelName]!
    }


    // MARK: Initializers

    public required init() {

    }

    public convenience init(dictionary: [String: AnyObject]) {
        self.init()
        self.update(dictionary)
    }

    public class func fromArray(array: [[String: AnyObject]]) -> [Model] {
        return array.map {
            let model = self.init()
            model.update($0)
            return model
        }
    }


    // MARK: Subscript

    public subscript(name: String) -> Any? {
        get {
            let mirror = Mirror(reflecting: self)
            for child in mirror.children {
                if child.label == name {
                    return child.value
                }
            }
            return nil
        }
        set {
            guard let property = self.dynamicType.properties[name] else {
                debugPrint("Property '\(name)' does not exist.")
                return
            }

            switch property.type {
            case Int.self, Optional<Int>.self:
                self.unsafeSetProperty(name, value: newValue as? Int)

            case Int8.self, Optional<Int8>.self:
                self.unsafeSetProperty(name, value: newValue as? Int8)

            case Int16.self, Optional<Int16>.self:
                self.unsafeSetProperty(name, value: newValue as? Int16)

            case Int32.self, Optional<Int32>.self:
                self.unsafeSetProperty(name, value: newValue as? Int32)

            case Int64.self, Optional<Int64>.self:
                self.unsafeSetProperty(name, value: newValue as? Int64)

            case UInt.self, Optional<UInt>.self:
                self.unsafeSetProperty(name, value: newValue as? UInt)

            case UInt8.self, Optional<UInt8>.self:
                self.unsafeSetProperty(name, value: newValue as? UInt8)

            case UInt16.self, Optional<UInt16>.self:
                self.unsafeSetProperty(name, value: newValue as? UInt16)

            case UInt32.self, Optional<UInt32>.self:
                self.unsafeSetProperty(name, value: newValue as? UInt32)

            case UInt64.self, Optional<UInt64>.self:
                self.unsafeSetProperty(name, value: newValue as? UInt64)

            case Float.self, Optional<Float>.self:
                self.unsafeSetProperty(name, value: newValue as? Float)
                
            case Double.self, Optional<Double>.self:
                self.unsafeSetProperty(name, value: newValue as? Double)
                
            case CGFloat.self, Optional<CGFloat>.self:
                self.unsafeSetProperty(name, value: newValue as? CGFloat)
                
            case Bool.self, Optional<Bool>.self:
                self.unsafeSetProperty(name, value: newValue as? Bool)

            case String.self, Optional<String>.self:
                self.unsafeSetProperty(name, value: newValue as? String)

            case NSDate.self, Optional<NSDate>.self:
                // TODO: NSDate
                break

            case NSURL.self, Optional<NSURL>.self:
                self.unsafeSetProperty(name, value: URLTransformer.transformedValue(newValue))

            case _ where property.displayStyle == .Enum:
                // Integer Enum
                if let rawValue = newValue as? Int {
                    self.unsafeSetProperty(name, value: rawValue)
                }

                // String Enum
                else if let defaultValue = property.defaultValue as? StringEnum,
                        let string = newValue as? String,
                        let enumValue = defaultValue.dynamicType.init(rawValue: string) {
                    self.unsafeSetProperty(name, value: enumValue.hashValue)
                }

                // Anything Else
                else {
                    fallthrough
                }

            default:
                let className = String(property.type).stringByReplacingOccurrencesOfString("Optional<", withString: "")
                                                     .stringByReplacingOccurrencesOfString(">", withString: "")

                // Relationship
                if let modelClass = self.classNamed(className) as? Model.Type,
                   let dictionary = newValue as? [String: AnyObject] {
                    let model = modelClass.init()
                    model.update(dictionary)
                    self.unsafeSetProperty(name, value: model)
                    break
                }

                // Array Relationship
                if className.hasPrefix("Array<") {
                    let elementTypeName = className.stringByReplacingOccurrencesOfString("Array<", withString: "")
                    if let elementType = self.classNamed(elementTypeName) as? Model.Type,
                       let array = newValue as? [[String: AnyObject]] {
                        let models = elementType.fromArray(array)
                        self.unsafeSetProperty(name, value: models)
                        break
                    }
                }
            }
        }
    }

    private func unsafeSetProperty<T>(name: String, value: T?) {
        let ivar = class_getInstanceVariable(self.dynamicType, name)
        if ivar.hashValue == 0 {
            return
        }

        // memory address for ivar
        let address = ObjectIdentifier(self).uintValue + UInt(ivar_getOffset(ivar))
        let pointer = UnsafeMutablePointer<T?>(bitPattern: address)
        pointer.memory = value
    }

    private func classNamed(className: String) -> AnyClass? {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let prefix = bundle.objectForInfoDictionaryKey(kCFBundleExecutableKey as String) as? String {
            return NSClassFromString(prefix + "." + className)
        }
        return NSClassFromString(className)
    }


    // MARK:

    public func update(dictionary: [String: AnyObject]) {
        for name in self.dynamicType.properties.keys {
            if let keyPath = self.dynamicType.JSONKeyPaths[name] {
                self[name] = self.dynamicType.valueForKeyPath(keyPath, inDictionary: dictionary)
            } else {
                self[name] = dictionary[name]
            }
        }
    }

    class func valueForKeyPath(keyPath: String, inDictionary dictionary: [String: AnyObject]) -> AnyObject? {
        var keys = keyPath.componentsSeparatedByString(".")
        let value = dictionary[keys.removeFirst()]
        if let subdictionary = value as? [String: AnyObject] {
            return valueForKeyPath(keys.joinWithSeparator("."), inDictionary: subdictionary)
        }
        return value
    }


    // MARK: JSONKeyPaths

    public class var JSONKeyPaths: [String: String] {
        return [:]
    }

}


// MARK: - Enum

public protocol StringEnum {

    init?(rawValue: String)

    var hashValue: Int { get }

}


// MARK: - Operators

private func ~= (lhs: Any.Type, rhs: Any.Type) -> Bool {
    return lhs == rhs
}

private func ~= (lhs: Optional<Any>.Type, rhs: Any.Type) -> Bool {
    return lhs == rhs
}
