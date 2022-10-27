# EDiOSAppUpdate

Keep users on the up-to date version of your App.

### Installation ###
---
  
### CocoaPods ####
  
[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate App update package into your Xcode project using CocoaPods, specify it in your Podfile:

``` 
'pod' 'EDiOSAppUpdate' 
```

## Usage

Setup AppVersion in your SceneDelegate.swift, code is self-explanatory:
 

```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let appVersion = AppVersion.shared
        appVersion.alertsEnabled = true //  UI alerts, presenting update options
        appVersion.alertType = .skippable // UI alert to include "Skip" button
        appVersion.neverEnabled = true // UI alert to include "Never" butoon
        appVersion.alertPresentationStyle = .actionSheet // UI presented as an actionSheet
        appVersion.checkBeforeUpdatePresented = { //present UI only if App Store version has more than 1 review and average rating is higher than 3
            return appVersion.appStoreVersionInfo?.version ??  AppInfo.shortVersion > AppInfo.shortVersion
        }
        appVersion.run()
        return true
    }

```

## Requirements

- Swift 5.0
- Xcode 11 or greater
- iOS 12.0 or greater
