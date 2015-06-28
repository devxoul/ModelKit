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

import UIKit
import XCTest
import SuperModel


@objc enum Gender: Int, StringEnum, Printable {
    case Unknown
    case Male
    case Female

    var rawValues: [Int: String?] {
        return [
            0: "unknown",
            1: "male",
            2: "female",
        ]
    }

    var description: String {
        return self.rawValues[self.rawValue]!?.capitalizedString ?? "unknown"
    }
}

class User: SuperModel {
    var id: Int!
    var name: String!
    var gender: Gender = .Unknown // enums must have a default value
    var bio: String?
    var city: String! = "Seoul"
    var posts: [Post]?
    var height: Float?
    var alive: Bool?
}

class Post: SuperModel {
    var id: Int!
    var title: String!
    var content: String?
    var author: User?
    var createdAt: NSDate?
    var publishedAt: NSDate?
    var authorName: String?
    var placeName: String?
    var placeLatitude: Float?
    var placeLongitude: Float?
    var URLString: String?
    var URL: NSURL?

    override class func dateFormatterForKey(key: String) -> NSDateFormatter? {
        if key == "createdAt" {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            return formatter
        }
        return nil
    }

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "URLString": "url",
            "URL": "url",
            "placeName": "place.name",
            "placeLatitude": "place.location.latitude",
            "placeLongitude": "place.location.longitude",
        ]
    }
}

class SuperModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        SuperModel.defaultDateFormatter.dateFormat = nil
        super.tearDown()
    }
    
    func testExample() {
        let dict = [
            "id": 123,
            "name": "devxoul",
            "bio": NSNull(),
        ]
        let user = User(dict)
        XCTAssertEqual(user.id, 123)
        XCTAssertEqual(user.name!, "devxoul")
        XCTAssertNil(user.bio)
        XCTAssertEqual(user.city, "Seoul")
    }

    func testExample2() {
        let dict = [
            "id": "1,300",
            "name": 132,
        ]
        let user = User(dict)
        XCTAssertEqual(user.id, 1300)
        XCTAssertEqual(user.name, "132")
    }

    func testList() {
        let response = [
            [
                "id": 123,
                "name": "devxoul",
                "bio": NSNull(),
            ],
            [
                "id": "1,300",
                "name": 132,
            ],
        ]
        let users = User.fromArray(response) as! [User]
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].id, 123)
        XCTAssertEqual(users[0].name, "devxoul")
        XCTAssertEqual(users[1].id, 1300)
        XCTAssertEqual(users[1].name, "132")
    }

    func testRelationship() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "author": [
                "id": 123,
                "name": "devxoul",
            ]
        ]
        let post = Post(dict)
        XCTAssertEqual(post.author!.id, 123)
        XCTAssertEqual(post.author!.name, "devxoul")
    }

    func testRelationshipList() {
        let dict: [String: NSObject] = [
            "id": 123,
            "name": "devxoul",
            "posts": [
                [
                    "id": 998,
                    "title": "Hello, Title!",
                ],
                [
                    "id": 999,
                    "title": "The Title",
                ]
            ]
        ]
        let user = User(dict)
        XCTAssertEqual(user.posts!.count, 2)
        XCTAssertEqual(user.posts![0].id, 998)
        XCTAssertEqual(user.posts![0].title, "Hello, Title!")
        XCTAssertEqual(user.posts![1].id, 999)
        XCTAssertEqual(user.posts![1].title, "The Title")
    }

    func testEnum() {
        let dict: [String: NSObject] = [
            "id": 2,
            "name": "devxoul",
            "gender": "male",
        ]
        let user = User(dict)
        XCTAssertEqual(user.gender, .Male)
    }

    func testDate() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "createdAt": "2015-01-02T14:33:55.123000+0900",
        ]

        let formatter = Post.dateFormatterForKey("createdAt")
        let post = Post(dict)
        XCTAssertEqual(formatter!.stringFromDate(post.createdAt!), dict["createdAt"] as! String)
    }

    func testURL() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "url": "http://xoul.kr",
        ]
        let post = Post(dict)
        XCTAssertEqual(post.URL!, NSURL(string: "http://xoul.kr")!)
    }

    func testDefaultDate() {
        SuperModel.defaultDateFormatter.dateFormat = "yyyy-MM-dd"
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "publishedAt": "2015-01-03",
        ]
        let post = Post(dict)
        XCTAssertEqual(SuperModel.defaultDateFormatter.stringFromDate(post.publishedAt!), "2015-01-03")
    }

    func testToDictionary() {
        let dict = [
            "id": 123,
            "name": "devxoul",
            "bio": NSNull(),
        ]
        let user = User(dict)
        XCTAssertEqual(user.toDictionary(), ["id": 123, "name": "devxoul", "city": "Seoul", "gender": "unknown"])
    }

    func testToDictionary2() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "createdAt": "2015-01-02T14:33:55.123000+0900",
            "author": [
                "id": 123,
                "name": "devxoul",
                "city": "Seoul",
                "gender": "unknown",
            ]
        ]
        let post = Post(dict)
        XCTAssertEqual(post.toDictionary(), dict)
    }

    func testToDictionary3() {
        let dict: [String: NSObject] = [
            "id": 123,
            "name": "devxoul",
            "city": "Daegu",
            "gender": "unknown",
            "posts": [
                [
                    "id": 998,
                    "title": "Hello, Title!",
                ],
                [
                    "id": 999,
                    "title": "The Title",
                ]
            ]
        ]
        let user = User(dict)
        XCTAssertEqual(user.toDictionary(), dict)
    }

    func testKeyPathForKeys() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "url": "http://xoul.kr"
        ]
        let post = Post(dict)
        XCTAssertEqual(post.URLString!, "http://xoul.kr")
    }

    func testKeyPathForKeys_depth2() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "place": [
                "name": "Starbucks",
                "location": [
                    "latitude": 1.23,
                    "longitude": 2.34
                ]
            ]
        ]
        let post = Post(dict)
        XCTAssertEqual(post.placeName!, "Starbucks")
    }

    func testKeyPathForKeys_depth3() {
        let dict: [String: NSObject] = [
            "id": 999,
            "title": "The Title",
            "place": [
                "name": "Starbucks",
                "location": [
                    "latitude": 1.23,
                    "longitude": 2.34
                ]
            ]
        ]
        let post = Post(dict)
        XCTAssertEqual(post.placeLatitude!, 1.23)
        XCTAssertEqual(post.placeLongitude!, 2.34)
    }

    func testSetterNameForKey() {
        XCTAssertEqual(SuperModel.propertySetterNameForKey(""), "")
        XCTAssertEqual(SuperModel.propertySetterNameForKey(":"), "set::")
        XCTAssertEqual(SuperModel.propertySetterNameForKey("name"), "setName:")
        XCTAssertEqual(SuperModel.propertySetterNameForKey("_privateName"), "set_privateName:")
    }

    func testNumberOptional() {
        let dict = [
            "height": 123.4,
        ]
        let user = User(dict)
        XCTAssertEqual(user.height ?? 0, 123.4)
        XCTAssertNil(user.alive)
    }

    func testNumberOptional2() {
        let dict = [
            "alive": true,
        ]
        let user = User(dict)
        XCTAssertEqual(user.alive ?? false, true)
    }

}
