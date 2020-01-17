//
//  AppConstant.swift
//  Litemint
//
//  Copyright © 2019 Litemint LLC All rights reserved.
//

import UIKit

enum EventHandlerType : String {
    
    case ready = "ready"
    case copyToClipboard = "copyToClipboard"
    case share = "share"
    case rate = "rate"
    case showToast = "showToast"
    case scanQRCode = "scanQRCode"
    case retrieveClipboardData = "retrieveClipboardData"
    case showNotification = "showNotification"
    
    
    case lockOrientation = "lockOrientation"
    case unlockOrientation = "unlockOrientation"
    
    
}


class AppConstant: NSObject {

    
}
///MARK:- Method to adjust lock and rotate to the desired orientation
   struct AppUtility {
   
       static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
           
           if let delegate = UIApplication.shared.delegate as? AppDelegate {
               delegate.orientationLock = orientation
           }
       }
       
       /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
       static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
           
           self.lockOrientation(orientation)
           
           UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
           UINavigationController.attemptRotationToDeviceOrientation()
       }
       
   }
   
   
