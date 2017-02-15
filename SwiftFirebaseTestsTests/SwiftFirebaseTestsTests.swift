//
//  SwiftFirebaseTestsTests.swift
//  SwiftFirebaseTestsTests
//
//  Created by Andy Chou on 2/10/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import XCTest
@testable import SwiftFirebaseTests

class SwiftFirebaseTestsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        auth.addStateDidChangeListener { auth, user in
            if let user = user {
                print("Logged in user \(user)")
            } else {
                print("Logged out")
            }
        }
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
