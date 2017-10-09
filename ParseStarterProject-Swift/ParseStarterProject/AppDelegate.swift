/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import UserNotifications
import StoreKit
import Foundation

import Parse

// If you want to use any of the UI components, uncomment this line
// import ParseUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //--------------------------------------
    // MARK: - UIApplicationDelegate
    //--------------------------------------

    let runIncrementerSetting = "numberOfRuns"  // UserDefauls dictionary key where we store number of runs
    let minimumRunCount = 3                     // Minimum number of runs that we should have until we ask for review
    
    func incrementAppRuns() {                   // counter for number of runs for the app. You can call this from App Delegate
        
        let usD = UserDefaults()
        let runs = getRunCounts() + 1
        usD.setValuesForKeys([runIncrementerSetting: runs])
        usD.synchronize()
        
    }
    
    func getRunCounts () -> Int {               // Reads number of runs from UserDefaults and returns it.
        
        let usD = UserDefaults()
        let savedRuns = usD.value(forKey: runIncrementerSetting)
        
        var runs = 0
        if (savedRuns != nil) {
            
            runs = savedRuns as! Int
        }
        
        print("Run Counts are \(runs)")
        return runs
        
    }
    
    func showReview() {
        
        let runs = getRunCounts()
        print("Show Review")
        
        if (runs == minimumRunCount) {
            
            if #available(iOS 10.3, *) {
                print("Review Requested")
                SKStoreReviewController.requestReview()
                
            } else {
                // Fallback on earlier versions
            }
            
        } else {
            
            print("Runs are not enough to request review!")
            
        }
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
            incrementAppRuns()
            showReview()
            return true

    
//         // get current number of times app has been launched
//                var currentCount: Int? = UserDefaults.standard.integer(forKey: "launchCount")
//                if currentCount == 0 {
//                    currentCount = 0
//                    print("currentcount is 0")
//                }
//        
//                    // increment received number by one
//                else {
//                    print("\(currentCount)")
//                    print("currentcount is not 0")
//                    UserDefaults.standard.set(currentCount!+1, forKey:"launchCount")
//        
//                    // save changes to disk
//                    UserDefaults.standard.synchronize()
//        
//                    if currentCount == 3 {
//                        if #available(iOS 10.3, *) {
//                            SKStoreReviewController.requestReview()
//                            print("current Count is 3")
//                        } else {
//                            // Fallback on earlier versions
//                            print("Rate is disabled")
//                        }
//                    }
//                }
        
        // ****************************************************************************
        // Initialize Parse SDK
        // ****************************************************************************

        let configuration = ParseClientConfiguration {
            // Add your Parse applicationId:
            $0.applicationId = "your_application_id"
            // Uncomment and add your clientKey (it's not required if you are using Parse Server):
            $0.clientKey = "your_client_key"

            // Uncomment the following line and change to your Parse Server address;
            $0.server = "https://YOUR_PARSE_SERVER/parse"

            // Enable storing and querying data from Local Datastore.
            // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
            $0.isLocalDatastoreEnabled = true
        }
        Parse.initialize(with: configuration)

        // ****************************************************************************
        // If you are using Facebook, uncomment and add your FacebookAppID to your bundle's plist as
        // described here: https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/
        // Uncomment the line inside ParseStartProject-Bridging-Header and the following line here:
        // PFFacebookUtils.initializeFacebook()
        // ****************************************************************************

        PFUser.enableAutomaticUser()

        let defaultACL = PFACL()

        // If you would like all objects to be private by default, remove this line.
        defaultACL.getPublicReadAccess = true

        PFACL.setDefault(defaultACL, withAccessForCurrentUser: true)

        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.

            let oldPushHandlerOnly = !responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var noPushPayload = false
            if let options = launchOptions {
                noPushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] == nil
            }
            if oldPushHandlerOnly || noPushPayload {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }

        if #available(iOS 10.0, *) {
            // iOS 10+
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                print("Notifications access granted: \(granted.description)")
            }
            application.registerForRemoteNotifications()
        } else {
            // iOS 8, 9
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        return true
    }

    //--------------------------------------
    // MARK: Push Notifications
    //--------------------------------------

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground()

        PFPush.subscribeToChannel(inBackground: "") { succeeded, error in
            if succeeded {
                print("ParseStarterProject successfully subscribed to push notifications on the broadcast channel.\n")
            } else {
                print("ParseStarterProject failed to subscribe to push notifications on the broadcast channel with error = %@.\n", error!)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error._code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.\n")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@\n", error)
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        PFPush.handle(userInfo)
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }

    ///////////////////////////////////////////////////////////
    // Uncomment this method if you want to use Push Notifications with Background App Refresh
    ///////////////////////////////////////////////////////////
    // func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    //     if application.applicationState == UIApplicationState.Inactive {
    //         PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
    //     }
    // }

    //--------------------------------------
    // MARK: Facebook SDK Integration
    //--------------------------------------

    ///////////////////////////////////////////////////////////
    // Uncomment this method if you are using Facebook
    ///////////////////////////////////////////////////////////
    // func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
    //     return FBAppCall.handleOpenURL(url, sourceApplication:sourceApplication, session:PFFacebookUtils.session())
    // }
}
