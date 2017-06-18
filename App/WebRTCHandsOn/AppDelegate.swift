//
//  AppDelegate.swift
//  WebRTCHandsOn
//
//  Created by TOMOHIKO OKITA on 2017/06/17.
//  Copyright © 2017年 TOMOHIKO OKITA. All rights reserved.
//

import UIKit
import WebRTC

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        RTCInitializeSSL()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        RTCCleanupSSL()
    }


}

