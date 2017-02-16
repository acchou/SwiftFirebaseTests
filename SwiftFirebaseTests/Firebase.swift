//
//  Firebase.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/12/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import Firebase

typealias FIRAppType = FIRApp
typealias FIRAuthType = FIRAuth
typealias FIRUserType = FIRUser

let app: FIRApp = FIRApp.defaultApp()!
let auth: FIRAuth = FIRAuth.auth()!
