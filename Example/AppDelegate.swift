//
//  AppDelegate.swift
//  Example
//
//  Created by BJIT on 10/10/22.
//

import UIKit
//import EDiOSAppUpdate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    

//https://github.com/amebalabs/AppVersion
//https://github.com/iMac0de/AppStoreVersion

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        let appVersion = AppVersion.shared
//        appVersion.alertsEnabled = true //  UI alerts, presenting update options
//        appVersion.alertType = .skippable // UI alert to include "Skip" button
//        appVersion.neverEnabled = true // UI alert to include "Never" butoon
//        appVersion.alertPresentationStyle = .actionSheet // UI presented as an actionSheet
//        appVersion.checkBeforeUpdatePresented = { //present UI only if App Store version has more than 1 review and average rating is higher than 3
//            print(appVersion.appStoreVersionInfo?.version ?? "1.0.0")
//            print(AppInfo.shortVersion)
//            
//            return appVersion.appStoreVersionInfo?.version ??  AppInfo.shortVersion > AppInfo.shortVersion
//            
//            //(self.appVersion.appStoreVersionInfo?.ratingsCount ?? 0) > 1
//           // && (self.appVersion.appStoreVersionInfo?.averageRating ?? 0) > 3
//        }
//
//        appVersion.run()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

