//
//  Global.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/27/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import GoogleAPIClientForREST
import RxSwift

var global = Global()

struct Global {
    var gmailService: GTLRGmailService
    var rxGmail: RxGmail
}

extension Global {
    init(gmailService: GTLRGmailService? = nil,
         rxGmail: RxGmail? = nil) {
        let gmailService = gmailService ?? GTLRGmailService()
        gmailService.isRetryEnabled = true
        gmailService.maxRetryInterval = 20

        let rxGmail = rxGmail ?? RxGmail(gmailService: gmailService)

        self.init(
            gmailService: gmailService,
            rxGmail: rxGmail
        )
    }
}
