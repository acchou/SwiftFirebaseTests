//
//  Gmail.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/15/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import GoogleAPIClientForREST

let gmailServiceScopes = [kGTLRAuthScopeGmailReadonly]
let gmailService = GTLRGmailService()

let info = Bundle.main.infoDictionary!
let GoogeClientID = info["GoogleClientID"] as! String
