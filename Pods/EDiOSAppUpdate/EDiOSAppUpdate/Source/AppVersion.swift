//
//  AppUpdate.swift
//  EDiOSAppUpdate
//
//  Created by BJIT on 6/9/22.
//


import Foundation
import UIKit

public final class AppVersion {
    
    public enum AlertType {
            case skippable
            case unskippable
            case blocking
        }

    /// AppVersion Singleton
    public static let shared = AppVersion()
    
    /// Defines the frequency of App Store update requests in **days**, default: 0 - means with each app launch
    public var updateFrequency: UInt = 0
    /// Checks you want to make before presenting update-suggesting UI. If returns **true** - UI will be presented, if **false** UI will be supressed
    public var checkBeforeUpdatePresented: (() -> Bool) = {return true}

    internal var currentVersion: SemanticVersion = {
        return SemanticVersion(stringLiteral: AppInfo.version)
    }()

    internal var currentAppStoreInfo: AppStoreVersion? {
        didSet {
            guard let version = currentAppStoreInfo?.currentVersion else { return }
            currentAppStoreVersion = version
        }
    }
    /// Inforfmation about the latest version available in App Store
    public var appStoreVersionInfo: AppStoreVersion? {
        return currentAppStoreInfo
    }

    internal var currentAppStoreVersion: SemanticVersion? {
        didSet {
            guard let currentAppStoreVersion = currentAppStoreVersion else { return }
            availableUpdateType = SemanticVersion.updateType(from: currentVersion, to: currentAppStoreVersion)
        }
    }

    internal var availableUpdateType: Version.UpdateType? {
        didSet {
            guard let availableUpdateType = availableUpdateType else { return }
            processUpdate(update: availableUpdateType)
        }
    }

    internal var updateAvailable: Bool {
        return ( availableUpdateType == .major || availableUpdateType == .minor || availableUpdateType == .patch)
    }

    /// Allows user to silence update-suggestion UI forever, i.e. alert will be never shown again. **False** by default
    public var neverEnabled: Bool = false
    /// Enables update-suggestion UI Alerts. **False** by default
    public var alertsEnabled: Bool = false
    /// Disables update-suggestion UI Alerts for **Minor** updates. **False** by default
    public var minorAlertsDisabled: Bool = false
    /// Disables update-suggestion UI Alerts for **Patch** updates. **False** by default
    public var patchAlertsDisabled: Bool = false
    /// UIAlertController alert presentation style. **alert** by default
    public var alertPresentationStyle: UIAlertController.Style = .alert
    /// Update-suggestion UI Alert Type, **unskippable** by default. Rewrites alertTypeMajor,alertTypeMinor and alertTypePatch when set.
    public var alertType: AlertType = .unskippable {
        didSet {
            alertTypeMajor = alertType
            alertTypeMinor = alertType
            alertTypePatch = alertType
        }
    }
    /// Update-suggestion UI Alert Type for **Major** update, **unskippable** by default.
    public var alertTypeMajor: AlertType?
    /// Update-suggestion UI Alert Type for **Minor** update, **unskippable** by default.
    public var alertTypeMinor: AlertType?
    /// Update-suggestion UI Alert Type for **Patch** update, **unskippable** by default.
    public var alertTypePatch: AlertType?

    /// Initializes AppVersion, call it from application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions:...) delegate in your AppDelegate
    /// Logs app launch and checks for an update in App Store
    public func run() {
        logLaunch()
        checkAppStoreForUpdate()
    }

    internal func checkAppStoreForUpdate(now: Bool = false) {
        if !now && updateFrequency != 0 {
            if let lastCheckDate = lastCheckDate, lastCheckDate.daysFromToday() < updateFrequency {
                print("To eraly to check!")
                return
            }
        }

        ItunesAPI.requestVersion { version, error in
            if let error = error {
                print(error)
                return
            }
            
            if let version = version {
                self.currentAppStoreInfo = version
                UserDefaults.appVersionLastCheckDate = Date()
            }
        }
    }

    /// Checks for update, non-blocking. Use it when you need to force the check ignoring `updateFrequency` setting
    public func checkAppStoreForUpdateNow() {
        checkAppStoreForUpdate(now: true)
    }

    private func logLaunch() {
        
        let launchCount = UserDefaults.appVersionHistory?[currentVersion] ?? 0
        var launchHistory = UserDefaults.appVersionHistory ?? [:]
        launchHistory[currentVersion] = launchCount + 1
        UserDefaults.appVersionHistory = launchHistory
    }

    internal func processUpdate(update: Version.UpdateType) {
        guard update != .none else { return }
       
        switch update {
        case .major:
            if alertsEnabled {
                showAlert(alertTypeMajor ?? alertType)
            }
        case .minor:
            if alertsEnabled, !minorAlertsDisabled {
                showAlert(alertTypeMinor ?? alertType)
            }
        case .patch:
            if alertsEnabled, !patchAlertsDisabled {
                showAlert(alertTypePatch ?? alertType)
            }
        case .none:
            print("Do nothing")
        }
    }

    private func launchAppStore() {
        if let appId = currentAppStoreInfo?.appId {
            UIApplication.shared.open(NSURL(string: "itms-apps://itunes.apple.com/app/\(appId)")! as URL, options: [: ], completionHandler: nil)
        }
    }

    internal func skipCurentAppStoreVersion() {
        UserDefaults.appVersionSkipVersion = currentAppStoreVersion //Bad?
    }

    internal func enableNeverShowAlert() {
        UserDefaults.appVersionNever = true
    }

    /// Resets all persistance information stored by AppVersion: version launch history and user preferences(skip, never)
    public func resetAppVersionState() {
        UserDefaults.resetAppVersionKeys()
    }
}

// MARK: UI Presenter
extension AppVersion {
    internal func showAlert(_ type: AlertType) {
        guard !UserDefaults.appVersionNever else { return }
        guard checkBeforeUpdatePresented() else { return }

        DispatchQueue.main.async {
            let alert = UIAlertController.appVersionAlert(self.alertPresentationStyle, version: self.currentAppStoreVersion?.string ?? "")
            alert.addUpdateAction(handler: self.launchAppStore)

            switch type {
            case .skippable:
                alert.addSkipAction(handler: self.skipCurentAppStoreVersion)
            case .unskippable:
                break
            case .blocking:
                break
            }

            if self.neverEnabled, type != .blocking {
                alert.addNeverAction(handler: self.enableNeverShowAlert)
            }

            alert.present()
        }
    }
}

// MARK: Launch history and user preferences
extension AppVersion {
    /// Date on which last check for update was performed
    public var lastCheckDate: Date? {
        return UserDefaults.appVersionLastCheckDate
    }
    /// Update version which user decided to skip
    public var skipVersion: Version? {
        return UserDefaults.appVersionSkipVersion
    }
    /// Version history installed & launched on this device, contains launch  counts for each version.
    /// Not preserved between reinstalls
    public var versionHistory: [Version: Int]? {
        return UserDefaults.appVersionHistory
    }
    /// Returns number of launches for this version
    public var launchesForThisVersion: Int {
        return UserDefaults.appVersionHistory?[currentVersion] ?? 1
    }
    /// Indicates if user asked to silence update-suggesting UI alerts
    public var neverShowAlert: Bool {
        return UserDefaults.appVersionNever
    }
}


extension Date {
    func daysFromToday() -> UInt {
        return UInt(abs(Calendar.current.dateComponents([.day], from: self, to: Date()).day!))
    }
}

public extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
}

public extension UserDefaults {
   
   private enum Keys {
       static let lastCheckDate = "EDiOSAppVersion.lastCheckDate"
       static let skipVersion = "EDiOSAppVersion.skipVersion"
       static let versionHistory = "EDiOSAppVersion.versionHistory"
       static let never = "EDiOSAppVersion.never"
   }

   static var appVersionLastCheckDate: Date? {
       get {
           return standard.object(forKey: Keys.lastCheckDate) as? Date
       }
       set {
           standard.set(newValue, forKey: Keys.lastCheckDate)
           standard.synchronize()
       }
   }

    static var appVersionSkipVersion: Version? {
       get {
           guard let version = standard.object(forKey: Keys.skipVersion) as? String else { return nil }
           return Version(stringLiteral: version)
       }
       set {
           standard.set(newValue?.string, forKey: Keys.skipVersion)
           standard.synchronize()
       }
   }

    static var appVersionHistory: [Version: Int]? {
       get {
           guard let data = standard.object(forKey: Keys.versionHistory) as? Data else { return nil }
           return try? PropertyListDecoder().decode([Version: Int].self, from: data)
       }
       set {
           standard.set(try? PropertyListEncoder().encode(newValue), forKey: Keys.versionHistory)
           standard.synchronize()
       }
   }

    static var appVersionNever: Bool {
       get {
           return standard.bool(forKey: Keys.never)
       }
       set {
           standard.set(newValue, forKey: Keys.never)
           standard.synchronize()
       }
   }

    static func resetAppVersionKeys() {
       standard.removeObject(forKey: Keys.lastCheckDate)
       standard.removeObject(forKey: Keys.skipVersion)
       standard.removeObject(forKey: Keys.versionHistory)
       standard.removeObject(forKey: Keys.never)
   }
}


typealias AlertHandler = () -> Void

extension UIAlertController {
    func present() {
        //UIWindowScene.windows
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first!.rootViewController?.present(self, animated: true, completion: nil)
    }

    static func appVersionAlert(_ style: UIAlertController.Style, version: String) -> UIAlertController {
        return UIAlertController(title: "Update Available", message: "Please update to version \(version) now.", preferredStyle: style)
    }

    @discardableResult
    func addCancleAction(handler: AlertHandler? = nil) -> Self {
        addAction(UIAlertAction(title: "Next Time", style: .cancel, handler: { _ in
            guard let handler = handler else { return }
            handler()
        }))
        return self
    }

    @discardableResult
    func addUpdateAction(handler: AlertHandler? = nil) -> Self {
        addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            guard let handler = handler else { return }
            handler()
        }))
        return self
    }

    @discardableResult
    func addSkipAction(handler: AlertHandler? = nil) -> Self {
        addAction(UIAlertAction(title: "Skip This Version", style: .default, handler: { _ in
            guard let handler = handler else { return }
            handler()
        }))
        return self
    }

    @discardableResult
    func addNeverAction(handler: AlertHandler? = nil) -> Self {
        addAction(UIAlertAction(title: "Never Suggest to Update", style: .destructive, handler: { _ in
            guard let handler = handler else { return }
            handler()
        }))
        return self
    }
}
