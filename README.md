# SwiftFirebaseTests
Tests for Firebase written in Swift.

One of the most frustrating things about working with an API like Firebase is
that you can't tell if it does what you think it does. Having tests helps
clarify what the API actually does, and when the API changes tests can give
early warning about incompatibilities and regressions that can cause clients
of the API to fail in hard to debug ways.

## Setup Introduction

There is some setup involved if you want to run this testsuite. The testsuite
requires access to cloud services to perform tests against them. You'll have
to sign up for these cloud services and set them up for testing:

* Firebase account: you'll need your own Firebase account to test against. If
  you already have a Firebase account, create a new project and a new app
  within that project to ensure this testsuite never touches any of your other
  app data.
  
* Facebook developer account: this testsuite needs access to a Facebook
  developer account to test Facebook login through Firebase Auth. Your
  Facebook account needs to be setup to allow for Firebase logins, described
  further below.
  
* Gmail account: some Firebase features send email. You'll need a gmail
  account to test these features. You'll also need to enable the gmail API, as
  described below.
  
Currently this testsuite does not test github or Twitter logins, so no
accounts are needed.

## Setup Steps

1. Clone this repository.

2. Open the workspace in Xcode. Make sure you open
   `SwiftFirebaseTests.xcworkspace`, not `SwiftFirebaseTests.xcodeproj`. The
   workspace contains references to Cocoapods dependencies (which aren't there
   yet, but will be soon). The project won't build yet, we have some more
   setup steps to perform first.

3. [Sign up for Firebase][]. In the [Firebase console][], create a test
   project (the name doesn't matter, but I would suggest `Testing`).
   
4. In the Firebase project you just created, click on **Add another app** and
   select **iOS**. Download the `GoogleService-Info.plist` file and place it
   into this project's root directory.
   
5. Create a gmail account for testing (do *not* use your primary email
   account).
   
6. Turn on the [Gmail API][] for your new Firebase project. Do not follow all
   of the instructions (which are for a quickstart project, not this
   project). Just follow the wizard link to automatically turn on the Gmail
   API, and select the test project you just created (`Testing`). Click cancel
   when prompted to add a crendential.
   
5. Sign up for [Facebook for developers][] (needed to test Facebook login
   through Firebase auth). Create a new app, the name doesn't matter but I
   would suggest `SwiftFirebaseTests`. Also make note of your **App ID** and
   **App Secret**. In the settings for your app, click on **Add Platform** and
   select **iOS**. Fill in the Bundle ID from this project's Bundle
   Identifier. The Bundle Identifier can be found in Xcode in the
   `SwiftFirebaseTests` target, under the `General` tab. Leave the other
   fields empty and save changes.
   
6. Enable [Facebook login for Firebase Auth][]. Follow the steps for **Before
   you begin**, skipping the step asking you to add the pod (it's already in
   this project). You should, however, enable facebook login in the Firebase
   console and add the **App ID** and **App Secret**, as well as set the
   **OAuth redirect URI** in your Facebook app's settings page as directed. Do
   not proceed into the section **Authenticate with Firebase** (in particular
   there is no need to integrate Facebook Login into the app, because it is
   integrated).

7. Add your cloud service details to `debug.xcconfig`. This file contains
   information that connects the project settings in this directory to cloud
   services. For example, Firebase Auth requires some changes to set a URL
   Type for Google login, and Facebook login requires changes to
   `Info.plist`. Instead of hard-coding settings like these into `Info.plist`,
   we use `debug.xcconfig` to store these settings locally. **This way your
   Firebase client ID and Facebook App ID are kept locally only, and never in
   the repository.** To create `debug.xcconfig`, copy
   `debug.xcconfig.template` and fill in these values:
   
   `GOOGLE_CLIENT_ID` should be set to the value of
   `CLIENT_ID` from `GoogleService-Info.plist`. It has the form:
   
     `GOOGLE_CLIENT_ID = XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

   `GOOGLE_REVERSED_CLIENT_ID` should be set to the value of
   `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`. It is used as a URL
   type: select the Info tab, and expand the URL Types section to see its
   usage, which fulfills the [Google sign-in URL Type][]. It should have the form:
   
     `GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
   
   `FACEBOOK_APP_ID` can be found in the [Facebook developer console][]. Make
   sure you use the **App ID** you created for this testsuite, not another
   one. This should consist of digits only.
   
     `FACEBOOK_APP_ID = XXXXXXXXXXXXXXXX`
   
   `FACEBOOK_DISPLAY_NAME` is the name of Facebook App you created. If you
   followed these directions, it should be `SwiftFirebaseTests`:
   
     `FACEBOOK_DISPLAY_NAME = SwiftFirebaseTests`
     
  `GMAIL_TEST_ACCOUNT` should be a gmail account used only for testing purposes:
  
     `GMAIL_TEST_ACCOUNT = XXXXX@gmail.com`
   
8. Change into the project directory and install dependencies with CocoaPods:
   
   ```
   $ pod install
   ```
   
   This should complete without warnings.

9. Return to Xcode. Build the workspace. It should build without errors.

## Database rules
TBD. Not used currently.

## Dynamic Links / Invites
TBD. Not used currently.

[Sign up for Firebase]: https://firebase.google.com
[Firebase console]: https://console.firebase.google.com
[Google sign-in URL Type]: https://firebase.google.com/docs/auth/ios/google-signin#2_implement_google_sign-in
[Facebook for developers]: https://developers.facebook.com/
[Facebook login for Firebase Auth]: https://firebase.google.com/docs/auth/ios/facebook-login
[Gmail API]: https://developers.google.com/gmail/api/quickstart/ios?ver=swift
