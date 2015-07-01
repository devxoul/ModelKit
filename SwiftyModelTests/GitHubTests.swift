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
import SwiftyModel
import XCTest


@objc enum GHState: Int, StringEnum {
    case Open
    case Closed

    var rawValues: [Int: String?] {
        return [
            GHState.Open.rawValue: "open",
            GHState.Closed.rawValue: "closed",
        ]
    }
}


class GHUser: SwiftyModel {
    var login: String!
    var id: NSNumber!
    var avatarURL: NSURL?
}


class GHLabel: SwiftyModel {
    var URL: NSURL!
    var name: String!
    var color: String!

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "URL": "url",
        ]
    }
}


class GHMilestone: SwiftyModel {
    var URL: NSURL!
    var HTMLURL: NSURL!
    var labelsURL: NSURL!
    var id: NSNumber!
    var state: GHState = .Closed
    var title: String!
    var descriptionText: String!
    var creator: GHUser!
    var openIssues: NSNumber!
    var closedIssues: NSNumber!
    var createdAt: NSDate!
    var updatedAt: NSDate!
    var closedAt: NSDate?
    var dueOn: NSDate?
    var comments: NSNumber!

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "URL": "url",
            "HTMLURL": "html_url",
            "labelsURL": "labels_url",
            "descriptionText": "description",
        ]
    }

    override class func dateFormatterForKey(key: String) -> NSDateFormatter? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter
    }
}


class GHIssue: SwiftyModel {
    var id: NSNumber!
    var URL: NSURL!
    var HTMLURL: NSURL!
    var number: NSNumber!
    var state: GHState = .Closed
    var title: String!
    var body: String!
    var user: GHUser!
    var labels: [GHLabel]?
    var assignee: GHUser?
    var milestone: GHMilestone?

    var milestoneCreatorLogin: String?

    override class func keyPathForKeys() -> [String: String]? {
        return [
            "URL": "url",
            "HTMLURL": "html_url",
            "milestoneCreatorLogin": "milestone.creator.login",
        ]
    }
}


class GitHubTests: XCTestCase {

    private let JSON: [[String: NSObject]] = [
        [
            "id": 1,
            "url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
            "html_url": "https://github.com/octocat/Hello-World/issues/1347",
            "number": 1347,
            "state": "open",
            "title": "Found a bug",
            "body": "I'm having a problem with this.",
            "user": [
                "login": "octocat",
                "id": 1,
                "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                "gravatar_id": "",
                "url": "https://api.github.com/users/octocat",
                "html_url": "https://github.com/octocat",
                "followers_url": "https://api.github.com/users/octocat/followers",
                "following_url": "https://api.github.com/users/octocat/following[/other_user]",
                "gists_url": "https://api.github.com/users/octocat/gists[/gist_id]",
                "starred_url": "https://api.github.com/users/octocat/starred[/owner][/repo]",
                "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                "organizations_url": "https://api.github.com/users/octocat/orgs",
                "repos_url": "https://api.github.com/users/octocat/repos",
                "events_url": "https://api.github.com/users/octocat/events[/privacy]",
                "received_events_url": "https://api.github.com/users/octocat/received_events",
                "type": "User",
                "site_admin": false
            ],
            "labels": [
                [
                    "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
                    "name": "bug",
                    "color": "f29513"
                ]
            ],
            "assignee": [
                "login": "octocat",
                "id": 1,
                "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                "gravatar_id": "",
                "url": "https://api.github.com/users/octocat",
                "html_url": "https://github.com/octocat",
                "followers_url": "https://api.github.com/users/octocat/followers",
                "following_url": "https://api.github.com/users/octocat/following[/other_user]",
                "gists_url": "https://api.github.com/users/octocat/gists[/gist_id]",
                "starred_url": "https://api.github.com/users/octocat/starred[/owner][/repo]",
                "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                "organizations_url": "https://api.github.com/users/octocat/orgs",
                "repos_url": "https://api.github.com/users/octocat/repos",
                "events_url": "https://api.github.com/users/octocat/events[/privacy]",
                "received_events_url": "https://api.github.com/users/octocat/received_events",
                "type": "User",
                "site_admin": false
            ],
            "milestone": [
                "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
                "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
                "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
                "id": 1002604,
                "number": 1,
                "state": "open",
                "title": "v1.0",
                "description": "Tracking milestone for version 1.0",
                "creator": [
                    "login": "octocat",
                    "id": 1,
                    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/octocat",
                    "html_url": "https://github.com/octocat",
                    "followers_url": "https://api.github.com/users/octocat/followers",
                    "following_url": "https://api.github.com/users/octocat/following[/other_user]",
                    "gists_url": "https://api.github.com/users/octocat/gists[/gist_id]",
                    "starred_url": "https://api.github.com/users/octocat/starred[/owner][/repo]",
                    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                    "organizations_url": "https://api.github.com/users/octocat/orgs",
                    "repos_url": "https://api.github.com/users/octocat/repos",
                    "events_url": "https://api.github.com/users/octocat/events[/privacy]",
                    "received_events_url": "https://api.github.com/users/octocat/received_events",
                    "type": "User",
                    "site_admin": false
                ],
                "open_issues": 4,
                "closed_issues": 8,
                "created_at": "2011-04-10T20:09:31Z",
                "updated_at": "2014-03-03T18:58:10Z",
                "closed_at": "2013-02-12T13:22:01Z",
                "due_on": "2012-10-09T23:39:01Z"
            ],
            "comments": 0,
            "pull_request": [
                "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
                "html_url": "https://github.com/octocat/Hello-World/pull/1347",
                "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
                "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch"
            ],
            "closed_at": NSNull(),
            "created_at": "2011-04-22T13:33:48Z",
            "updated_at": "2011-04-22T13:33:48Z"
        ]
    ]

    func testTest() {
        let issues = GHIssue.fromArray(JSON) as! [GHIssue]
        XCTAssertEqual(count(issues), 1)

        let issue = issues.first!
        XCTAssertEqual(issue.id, 1)
        XCTAssertEqual(issue.URL, NSURL(string: "https://api.github.com/repos/octocat/Hello-World/issues/1347")!)
        XCTAssertEqual(issue.HTMLURL, NSURL(string: "https://github.com/octocat/Hello-World/issues/1347")!)
        XCTAssertEqual(issue.number, 1347)
        XCTAssertEqual(issue.state, GHState.Open)
        XCTAssertEqual(issue.title, "Found a bug")
        XCTAssertEqual(issue.body, "I'm having a problem with this.")

        XCTAssertEqual(issue.user.login, "octocat")

        XCTAssertEqual(count(issue.labels!), 1)
        XCTAssertEqual(issue.labels![0].URL, NSURL(string: "https://api.github.com/repos/octocat/Hello-World/labels/bug")!)
        XCTAssertEqual(issue.labels![0].name, "bug")
        XCTAssertEqual(issue.labels![0].color, "f29513")

        XCTAssertEqual(issue.assignee!.login, "octocat")

        XCTAssertEqual(issue.milestone!.title, "v1.0")
        XCTAssertEqual(issue.milestoneCreatorLogin!, "octocat")
    }

}
