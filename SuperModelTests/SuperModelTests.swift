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

class User: SuperModel {
    var id: Number!
    var name: String!
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

    override class func dateFormatterForKey(key: String) -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return formatter
    }
}

class SuperModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        XCTAssertEqual(user.toDictionary(), ["id": 123, "name": "devxoul", "city": "Seoul"])
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

    func testDate() {
        let dict: Dict = [
            "id": 999,
            "title": "The Title",
            "createdAt": "2015-01-02T14:33:55.123000+0900",
        ]

        let formatter = Post.dateFormatterForKey("")
        let post = Post(dict)
        XCTAssertEqual(formatter.stringFromDate(post.createdAt!), dict["createdAt"] as! String)
    }
    
}
