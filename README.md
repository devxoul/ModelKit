SuperModel
==========

[![CocoaPods](http://img.shields.io/cocoapods/v/SuperModel.svg?style=flat)](https://cocoapods.org/pods/SuperModel)

Model framework for Swift.


At a Glance
-----------

Let's assume that we use [GitHub Issues API](https://developer.github.com/v3/issues/). It would be looked like this:

```swift
@objc enum GHState: Int, StringEnum {
    case Open
    case Closed

    var rawValues: [Int: String] {
        return [
            GHState.Open.rawValue: "open",
            GHState.Closed.rawValue: "closed",
        ]
    }
}

class GHIssue: SuperModel {
    var id: NSNumber!
    var URL: NSURL!
    var HTMLURL: NSURL!
    var number: NSNumber!
    var state: GHState = .Closed // enum must have a default value
    var title: String!
    var body: String!
    var user: GHUser!
    var labels: [GHLabel]?
    var milestoneTitle: String?

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "URL": "url",
            "HTMLURL": "html_url",
            "milestoneTitle": "milestone.title",
        ]
    }
    
    override class func dateFormatterForKey(key: String) -> NSDateFormatter? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter
    }
}
```


Installation
------------

### iOS 8+

Use [CocoaPods](https://cocoapods.org). Minimum required version of CocoaPods is 0.36, which supports Swift frameworks.

**Podfile**

```ruby
pod 'SuperModel'
```


### iOS 7

I recommend you to try [CocoaSeeds](https://github.com/devxoul/CocoaSeeds), which uses source code instead of dynamic framework.

**Seedfile**

```ruby
github 'devxoul/SuperModel', '0.0.2', :files => 'SuperModel/SuperModel.swift'
```


Models from JSON
----------------

#### Single Model

```swift
let issue = GHIssue(JSONDictionary)
```

#### Array of Model

```swift
let issues = GHIssue.fromArray(JSONArray) as! [GHIssue]
```


Enums
-----

SuperModel supports enums with limitation of Swift. There are two kinds of enums: `SuperEnum` and `StringEnum`. `SuperEnum` described integer enums and `StringEnum` describes string enums.

- Enums should be declard with `@objc` attribute.
- Enum's raw type must be `Int` with `SuperEnum` or `StringEnum` protocol.
- `StringEnum` must implement `rawValues()` function.

**Example of `SuperEnum`**

```swift
@objc enum Direction: Int, SuperEnum {
    case Up
    case Down
    case Left
    case Right
}
```

**Example of `StringEnum`**

```swift
@objc enum GHState: Int, StringEnum {
    case Open
    case Closed

    var rawValues: [Int: String] {
        return [
            GHState.Open.rawValue: "open",
            GHState.Closed.rawValue: "closed",
        ]
    }
}
```


License
-------

SuperModel is under MIT license. See the LICENSE file for more info.
