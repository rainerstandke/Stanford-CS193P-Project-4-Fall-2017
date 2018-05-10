//
//  AppDelegate.swift
//  Set Game
//
//  Created by Rainer Standke on 2/3/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		if ProcessInfo.processInfo.environment["XCInjectBundleInto"] != nil {
			return false
		}
		
		return true
	}
}

