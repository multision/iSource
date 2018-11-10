//
//  SettingsTableVC.swift
//  iSource
//
//  Created by user on 6/16/18.
//  Copyright © 2018 MasonD3V. All rights reserved.
//

import UIKit
import TVAlert

class SettingsTableVC: UITableViewController {

    @IBOutlet weak var udid: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        if UserDefaults.standard.value(forKey: "udid") == nil {
            print("UDID has not yet been fetched.")
        } else {
            let newUdid = (UserDefaults.standard.value(forKey: "udid") as! String).replacingOccurrences(of: "isource://?udid=", with: "")
            udid.text = "\(newUdid)"
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            if udid.text != "Fetching Needed" {
                UIPasteboard.general.string = udid.text
                
                let alert = TVAlertController(title: "iSource", message: "You have copied your UDID to your clipboard.\n\n\(udid.text!)", preferredStyle: .alert)
                let cancelAction = TVAlertAction(title: "Not a UDID?", style: .destructive) { (_) in
                    
                    let alertController = TVAlertController(title: "iSource", message: "Type in your UDID that you have recieved then press submit.", preferredStyle: .alert)
                    let cancelAction = TVAlertAction(title: "Cancel", style: .destructive) { (_) in }
                    let searchAction = TVAlertAction(title: "Submit", style: .default) { (_) in
                        let channelTextField = alertController.textFields![0] as UITextField
                        UserDefaults.standard.set("\(channelTextField.text!)", forKey: "udid")
                    }
                    searchAction.isEnabled = false
                    alertController.addTextField { (textField) in
                        textField.placeholder = "UDID"
                        NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                            searchAction.isEnabled = textField.text != ""
                        }
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(searchAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                alert.addAction(cancelAction)
                alert.addAction(TVAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                let urlString = "https://jelteam.000webhostapp.com/iSource"
                if let url = URL(string: urlString) {
                    UIApplication.shared.openURL(url)
                }
            }
        } else if indexPath.section == 1 && indexPath.row == 0 {
            let urlString = "https://twitter.com/masond3v"
            if let url = URL(string: urlString) {
                UIApplication.shared.openURL(url)
            }
        } else if indexPath.section == 1 && indexPath.row == 1 {
            let urlString = "https://twitter.com/maxrield"
            if let url = URL(string: urlString) {
                UIApplication.shared.openURL(url)
            }
        } else if indexPath.section == 1 && indexPath.row == 2 {
            let urlString = "https://twitter.com/antonio07341176"
            if let url = URL(string: urlString) {
                UIApplication.shared.openURL(url)
            }
        } else if indexPath.section == 1 && indexPath.row == 3 {
            let urlString = "https://twitter.com/nwtoo"
            if let url = URL(string: urlString) {
                UIApplication.shared.openURL(url)
            }
        } else if indexPath.section == 1 && indexPath.row == 4 {
            let urlString = "https://icons8.com"
            if let url = URL(string: urlString) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
}
