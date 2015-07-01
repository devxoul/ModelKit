SwiftyModel
==========

[![CocoaPods](http://img.shields.io/cocoapods/v/SwiftyModel.svg?style=flat)](https://cocoapods.org/pods/SwiftyModel)

Model framework for Swift.


Feautres
--------

* [JSON Mapping](#json-mapping)
* [Optional Support](#optionals)
* [Enum Support](#enums)
* [Relationship](#relationship)


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

class GHIssue: SwiftyModel {
    var id: Int!
    var URL: NSURL!
    var HTMLURL: NSURL!
    var number: Int!
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
pod 'SwiftyModel'
```


### iOS 7

I recommend you to try [CocoaSeeds](https://github.com/devxoul/CocoaSeeds), which uses source code instead of dynamic framework.

**Seedfile**

```ruby
github 'SwiftyModel/SwiftyModel', '0.1.0', :files => 'SwiftyModel/SwiftyModel.swift'
```


JSON Mapping
------------

#### Initialize Single Object from JSON Dictionary

```swift
let issue = GHIssue(JSONDictionary)
```

#### Initialize Objects from JSON Array

```swift
let issues = GHIssue.fromArray(JSONArray) as! [GHIssue]
```

#### Property from JSON KeyPaths

```json
{
    "id": 123,
    "author": {
        "id": 456,
        "name": "Suyeol Jeon",
        "nickname": "devxoul"
    }
}
```

```swift
class Post: SwiftyModel {
    var id: Int!
    var authorID: Int! // will be `456`
    var authorNickname: String? // will be `devxoul`

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "authorID": "author.id",
            "authorNickname": "author.nickname",
        ]
    }
```


#### Object Serializing

```json
    let post = Post(JSONDictionary)
    post.toDictionary() // will return JSON dictionary
```


Optionals
---------

SwiftyModel fully supports Optional. No more `NSNumber`, and no more initialized properties.

```swift
class HealthData: SwiftyModel {
    var birthyear: Int?
    var weight: Float?
}

let health = HelathData(...)
if let weight = health.weight {
    ...
}
```

> **Note:** SwiftyModel isn't compatible with Objective-C if you're using primitive type optionals. (e.g. `Int?`, `Float!`, `Bool?`) Because those are not converted to Objective-C.



Enums
-----

SwiftyModel supports enums with limitation of Swift. There are two kinds of enums: `SuperEnum` and `StringEnum`. `SuperEnum` described integer enums and `StringEnum` describes string enums.

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


Relationship
------------

You can define replationships between models.

```swift
class Post: SwiftyModel {
    var author: User!
    var comments: [Comment]?
}
```


License
-------

SwiftyModel is under MIT license. See the LICENSE file for more info.
