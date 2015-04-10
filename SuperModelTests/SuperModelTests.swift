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
    var author: User!
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
    
}
