//
//  ViewController.swift
//  iSource
//
//  Created by user on 6/15/18.
//  Copyright © 2018 MasonD3V. All rights reserved.
//

import UIKit
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import Foundation
import AdSupport

class ViewController: UITableViewController {
    
    @IBOutlet weak var lanIP: UILabel!
    @IBOutlet weak var storageRatio: UILabel!
    @IBOutlet weak var totalStorage: UILabel!
    @IBOutlet weak var usedStorage: UILabel!
    @IBOutlet weak var freeStorage: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceModel: UILabel!
    @IBOutlet weak var deviceOS: UILabel!
    @IBOutlet weak var deviceUUID: UILabel!
    @IBOutlet weak var deviceIDFA: UILabel!
    @IBOutlet weak var batteryLevel: UILabel!
    @IBOutlet weak var lpmsStatus: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var processor: UILabel!
    @IBOutlet weak var kernelRelease: UILabel!
    
    func getCurrentDateTime() {
        let formatter = DateFormatter()
        //formatter.dateStyle = .long
        //formatter.timeStyle = .none
        //formatter.dateFormat = "EEEE, MMM, dd, yyyy HH:mm a"
        formatter.dateFormat = "EEEE, MMMM d"
        let str = formatter.string(from: Date())
        date.text = str.description
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(DeviceInfo.getDeviceInfo())
        //tableview updater
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        //classification
        tableView.delegate = self
        tableView.dataSource = self
        UIApplication.shared.statusBarStyle = .lightContent
        UIDevice.current.isBatteryMonitoringEnabled = true
        //tableview labels
        if getWiFiAddress() != nil {
            lanIP.text = "\(getWiFiAddress()!)"
        } else {
            lanIP.text = "Error: No WiFi"
        }
        storageRatio.text = "\(DiskStatus.usedDiskSpace) / \(DiskStatus.totalDiskSpace)"
        totalStorage.text = "\(DiskStatus.totalDiskSpace)"
        usedStorage.text = "\(DiskStatus.usedDiskSpace)"
        freeStorage.text = "\(DiskStatus.freeDiskSpace)"
        deviceName.text = "\(UIDevice.current.name)"
        deviceModel.text = "\(modelIdentifier()) (\(UIDevice().type))"
        deviceOS.text = "\(UIDevice.current.systemVersion) (\(DeviceInfo.getBuildID()!))"
        deviceUUID.text = "\(UIDevice.current.identifierForVendor!.uuidString)"
        if identifierForAdvertising() != nil {
            deviceIDFA.text = "\(identifierForAdvertising()!)"
        } else {
            deviceIDFA.text = "Error: Limit Ad Tracking is enabled."
        }
        let batteryStr = "\(UIDevice.current.batteryLevel*100)"
        let newBatteryStr = batteryStr.dropLast(2)
        batteryLevel.text = "\(newBatteryStr)%"
        if ProcessInfo.processInfo.isLowPowerModeEnabled == true {
            lpmsStatus.text = "Low Power Mode is enabled."
        } else {
            lpmsStatus.text = "Low Power Mode is disabled."
        }
        processor.text = "Apple \(UIDevice.current.getCPUName()) @ \(UIDevice.current.getCPUSpeed())"
        kernelRelease.text = "\(DeviceInfo.getKernel()!)"
        getCurrentDateTime()
    }
    
    @objc func update() {
        //tableview labels
        if getWiFiAddress() != nil {
            lanIP.text = "\(getWiFiAddress()!)"
        } else {
            lanIP.text = "Error: No WiFi"
        }
        storageRatio.text = "\(DiskStatus.usedDiskSpace) / \(DiskStatus.totalDiskSpace)"
        totalStorage.text = "\(DiskStatus.totalDiskSpace)"
        usedStorage.text = "\(DiskStatus.usedDiskSpace)"
        freeStorage.text = "\(DiskStatus.freeDiskSpace)"
        deviceName.text = "\(UIDevice.current.name)"
        deviceModel.text = "\(modelIdentifier()) (\(UIDevice().type))"
        deviceOS.text = "\(UIDevice.current.systemVersion) (\(DeviceInfo.getBuildID()!))"
        deviceUUID.text = "\(UIDevice.current.identifierForVendor!.uuidString)"
        if identifierForAdvertising() != nil {
            deviceIDFA.text = "\(identifierForAdvertising()!)"
        } else {
            deviceIDFA.text = "Error: Limit Ad Tracking is enabled."
        }
        let batteryStr = "\(UIDevice.current.batteryLevel*100)"
        let newBatteryStr = batteryStr.dropLast(2)
        batteryLevel.text = "\(newBatteryStr)%"
        if ProcessInfo.processInfo.isLowPowerModeEnabled == true {
            lpmsStatus.text = "Low Power Mode is enabled."
        } else {
            lpmsStatus.text = "Low Power Mode is disabled."
        }
        processor.text = "Apple \(UIDevice.current.getCPUName()) @ \(UIDevice.current.getCPUSpeed())"
        kernelRelease.text = "\(DeviceInfo.getKernel()!)"
        getCurrentDateTime()
    }

}

// Everything after viewDidLoad is code for the table view.

var batteryLevel: Float {
    return UIDevice.current.batteryLevel*100
}

func modelIdentifier() -> String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
    var sysinfo = utsname()
    uname(&sysinfo) // ignore return value
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}

// Return SSID
func getWiFiSsid() -> String? {
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }
    }
    return ssid
}

// Return IP address of WiFi interface (en0) as a String, or `nil`
func getWiFiAddress() -> String? {
    var address : String?
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    
    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        
        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            
            // Check interface name:
            let name = String(cString: interface.ifa_name)
            if  name == "en0" {
                
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)
    
    return address
}

func identifierForAdvertising() -> String? {
    // Check whether advertising tracking is enabled
    guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
        return nil
    }
    
    // Get and return IDFA
    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
}

func isConnectedToNetwork() -> Bool {
    
    var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }
    
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    
    return (isReachable && !needsConnection)
    
}

public enum Model : String {
    case simulator     = "simulator/sandbox",
    iPod1              = "iPod 1",
    iPod2              = "iPod 2",
    iPod3              = "iPod 3",
    iPod4              = "iPod 4",
    iPod5              = "iPod 5",
    iPad2              = "iPad 2",
    iPad3              = "iPad 3",
    iPad4              = "iPad 4",
    iPad5              = "iPad 5",
    iPhone4            = "iPhone 4",
    iPhone4S           = "iPhone 4S",
    iPhone5            = "iPhone 5",
    iPhone5S           = "iPhone 5S",
    iPhone5C           = "iPhone 5C",
    iPadMini1          = "iPad Mini 1",
    iPadMini2          = "iPad Mini 2",
    iPadMini3          = "iPad Mini 3",
    iPadAir1           = "iPad Air 1",
    iPadAir2           = "iPad Air 2",
    iPadPro9_7         = "iPad Pro 9.7\"",
    iPadPro9_7_cell    = "iPad Pro 9.7\" cellular",
    iPadPro12_9        = "iPad Pro 12.9\"",
    iPadPro12_9_cell   = "iPad Pro 12.9\" cellular",
    iPadPro2_12_9      = "iPad Pro 2 12.9\"",
    iPadPro2_12_9_cell = "iPad Pro 2 12.9\" cellular",
    iPhone6            = "iPhone 6",
    iPhone6plus        = "iPhone 6 Plus",
    iPhone6S           = "iPhone 6S",
    iPhone6Splus       = "iPhone 6S Plus",
    iPhoneSE           = "iPhone SE",
    iPhone7            = "iPhone 7",
    iPhone7plus        = "iPhone 7 Plus",
    iPhone8            = "iPhone 8",
    iPhone8plus        = "iPhone 8 Plus",
    iPhoneX            = "iPhone X",
    unrecognized       = "?unrecognized?"
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK: UIDevice extensions
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#

public extension UIDevice {
    public var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
                
            }
        }
        var modelMap : [ String : Model ] = [
            "i386"      : .simulator,
            "x86_64"    : .simulator,
            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,
            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad2,5"   : .iPadMini1,
            "iPad2,6"   : .iPadMini1,
            "iPad2,7"   : .iPadMini1,
            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPad4,2"   : .iPadAir1,
            "iPad5,4"   : .iPadAir2,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7_cell,
            "iPad6,12"  : .iPad5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9_cell,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9_cell,
            "iPhone7,1" : .iPhone6plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6Splus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,2" : .iPhone7plus,
            "iPhone9,3" : .iPhone7,
            "iPhone9,4" : .iPhone7plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,2" : .iPhone8plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,4" : .iPhone8,
            "iPhone10,5" : .iPhone8plus,
            "iPhone10,6" : .iPhoneX
        ]
        
        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            if model == .simulator {
                if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                    if let simModel = modelMap[String.init(validatingUTF8: simModelCode)!] {
                        return simModel
                    }
                }
            }
            return model
        }
        return Model.unrecognized
    }
}

public extension UIDevice
{
    //Original Author: HAS
    // https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    // Modified by Sam Trent
    
    /**********************************************
     *  getCPUName():
     *     Returns a hardcoded value of the current
     * devices CPU name.
     ***********************************************/
    public func getCPUName() -> String
    {
        var processorNames = Array(CPUinfo().keys)
        return processorNames[0]
    }
    
    /**********************************************
     *  getCPUSpeed():
     *     Returns a hardcoded value of the current
     * devices CPU speed as specified by Apple.
     ***********************************************/
    public func getCPUSpeed() -> String
    {
        var processorSpeed = Array(CPUinfo().values)
        return processorSpeed[0]
    }
    
    /**********************************************
     *  CPUinfo:
     *     Returns a dictionary of the name of the
     *  current devices processor and speed.
     ***********************************************/
    private func CPUinfo() -> Dictionary<String, String> {
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
        #else
            
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8 , value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
        
        switch identifier {
        case "iPod5,1":                                 return ["A5":"800 MHz"] // underclocked
        case "iPod7,1":                                 return ["A8":"1.4 GHz"]
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return ["A4":"800 MHz"] // underclocked
        case "iPhone4,1":                               return ["A5":"800 MHz"] // underclocked
        case "iPhone5,1", "iPhone5,2":                  return ["A6":"1.3 GHz"]
        case "iPhone5,3", "iPhone5,4":                  return ["A6":"1.3 GHz"]
        case "iPhone6,1", "iPhone6,2":                  return ["A7":"1.3 GHz"]
        case "iPhone7,2":                               return ["A8":"1.4 GHz"]
        case "iPhone7,1":                               return ["A8":"1.4 GHz"]
        case "iPhone8,1":                               return ["A9":"1.85 GHz"]
        case "iPhone8,2":                               return ["A9":"1.85 GHz"]
        case "iPhone9,1", "iPhone9,3":                  return ["A10 Fusion":"2.34 GHz"]
        case "iPhone9,2", "iPhone9,4":                  return ["A10 Fusion":"2.34 GHz"]
        case "iPhone8,4":                               return ["A9":"1.85 GHz"]
        case "iPhone10,1", "iPhone10,4":                return ["A11 Bionic":"2.39 GHz"]
        case "iPhone10,2", "iPhone10,5":                return ["A11 Bionic":"2.39 GHz"]
        case "iPhone10,3", "iPhone10,6":                return ["A11 Bionic":"2.39 GHz"]
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return ["A5":"1.0 GHz"]
        case "iPad3,1", "iPad3,2", "iPad3,3":           return ["A5X":"1.0 GHz"]
        case "iPad3,4", "iPad3,5", "iPad3,6":           return ["A6X":"1.4 GHz"]
        case "iPad4,1", "iPad4,2", "iPad4,3":           return ["A7":"1.4 GHz"]
        case "iPad5,3", "iPad5,4":                      return ["A8X":"1.5 GHz"]
        case "iPad6,11", "iPad6,12":                    return ["A9":"1.85 GHz"]
        case "iPad2,5", "iPad2,6", "iPad2,7":           return ["A5":"1.0 GHz"]
        case "iPad4,4", "iPad4,5", "iPad4,6":           return ["A7":"1.3 GHz"]
        case "iPad4,7", "iPad4,8", "iPad4,9":           return ["A7":"1.3 GHz"]
        case "iPad5,1", "iPad5,2":                      return ["A8":"1.5 GHz"]
        case "iPad6,3", "iPad6,4":                      return ["A9X":"2.16 GHz"] // underclocked
        case "iPad6,7", "iPad6,8":                      return ["A9X":"2.24 GHz"]
        case "iPad7,1", "iPad7,2":                      return ["A10X Fusion":"2.34 GHz"]
        case "iPad7,3", "iPad7,4":                      return ["A10X Fusion":"2.34 GHz"]
        case "AppleTV5,3":                              return ["A8":"1.4 GHz"]
        case "AppleTV6,2":                              return ["A10X Fusion":"2.34 GHz"]
        case "AudioAccessory1,1":                       return ["A8":"1.4 GHz"] // clock speed is a guess
        default:                                        return ["N/A":"N/A"]
        }
    }
}
