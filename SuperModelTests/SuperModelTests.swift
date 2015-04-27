//
//  SuperModelTests.swift
//  SuperModelTests
//
//  Created by 전수열 on 4/11/15.
//  Copyright (c) 2015 Suyeol Jeon. All rights reserved.
//

import UIKit
import XCTest
import SuperModel


@objc enum Gender: Int, StringEnum, Printable {
    case Unknown
    case Male
    case Female

    var stringValue: String {
        switch self {
        case .Unknown: return "unknown"
        case .Male: return "male"
        case .Female: return "female"
        }
    }

    func fromInt(int: Int) -> Gender {
        return Gender(rawValue: int) ?? .Unknown
    }

    func fromString(string: String) -> Gender {
        switch string {
        case "male": return Gender.Male
        case "female": return Gender.Female
        default: return Gender.Unknown
        }
    }

    var description: String { return self.stringValue.capitalizedString }
}

class User: SuperModel {
    var id: Number!
    var name: String!
    var gender: Gender = .Unknown // enums must have a default value
    var bio: String?
    var city: String! = "Seoul"
    var posts: [Post]?
}

class Post: SuperModel {
    var id: Number!
    var title: String!
    var content: String?
    var author: User?
    var createdAt: NSDate?
    var publishedAt: NSDate?
    var authorName: String?
    var placeName: String?
    var placeLatitude: Number?
    var placeLongitude: Number?
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
            "id": "1,300.123",
            "name": 132,
        ]
        let user = User(dict)
        XCTAssertEqual(user.id, 1300.123)
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
                "id": "1,300.123",
                "name": 132,
            ],
        ]
        let users = User.fromList(response) as! [User]
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].id, 123)
        XCTAssertEqual(users[0].name, "devxoul")
        XCTAssertEqual(users[1].id, 1300.123)
        XCTAssertEqual(users[1].name, "132")
    }

    func testRelationship() {
        let dict: Dict = [
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
        let dict: Dict = [
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
        let dict: Dict = [
            "id": 2,
            "name": "devxoul",
            "gender": "male",
        ]
        let user = User(dict)
        XCTAssertEqual(user.gender, .Male)
    }

    func testDate() {
        let dict: Dict = [
            "id": 999,
            "title": "The Title",
            "createdAt": "2015-01-02T14:33:55.123000+0900",
        ]

        let formatter = Post.dateFormatterForKey("createdAt")
        let post = Post(dict)
        XCTAssertEqual(formatter!.stringFromDate(post.createdAt!), dict["createdAt"] as! String)
    }

    func testURL() {
        let dict: Dict = [
            "id": 999,
            "title": "The Title",
            "url": "http://xoul.kr",
        ]
        let post = Post(dict)
        XCTAssertEqual(post.URL!, NSURL(string: "http://xoul.kr")!)
    }

    func testDefaultDate() {
        SuperModel.defaultDateFormatter.dateFormat = "yyyy-MM-dd"
        let dict: Dict = [
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
        let dict: Dict = [
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
        let dict: Dict = [
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
        let dict: Dict = [
            "id": 999,
            "title": "The Title",
            "url": "http://xoul.kr"
        ]
        let post = Post(dict)
        XCTAssertEqual(post.URLString!, "http://xoul.kr")
    }

    func testKeyPathForKeys_depth2() {
        let dict: Dict = [
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
        let dict: Dict = [
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

}
