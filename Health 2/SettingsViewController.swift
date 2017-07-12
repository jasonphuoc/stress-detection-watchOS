//
//  SettingsViewController.swift
//  Health 2
//
//  Created by Jason La on 3/27/17.
//  Copyright © 2017 Jason La. All rights reserved.
//

import UIKit
import WatchConnectivity

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, WCSessionDelegate {

    @IBOutlet weak var startIntervalPicker: UIPickerView!
    @IBOutlet weak var endIntervalPicker: UIPickerView!
    @IBOutlet weak var trainingFrequencyPicker: UIPickerView!
    @IBOutlet weak var monitoringFrequencyPicker: UIPickerView!
    @IBOutlet weak var notificationPicker: UIPickerView!
    
    var session: WCSession!
    let defaults = UserDefaults(suiteName: "group.com.jasonla-stress")
    
    var pickerHours = ["12 am", "1 am", "2 am", "3 am", "4 am", "5 am", "6 am", "7 am", "8 am", "9 am", "10 am", "11 am", "12 pm", "1 pm", "2 pm", "3 pm", "4 pm", "5 pm", "6 pm", "7 pm", "8 pm", "9 pm", "10 pm", "11 pm", "12 am"]
    var pickerMonitorFrequencies = ["15 minutes", "30 minutes", "1 hour", "2 hours", "3 hours", "4 hours", "5 hours", "6 hours"]
    var pickerTrainingFrequencies = ["30 minutes", "1 hour", "2 hours", "3 hours", "4 hours"]
    var pickerNotifications = ["A little stressed", "Moderately stressed", "Very stressed"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self;
            session.activate()
        }
        
        self.startIntervalPicker.dataSource = self
        self.startIntervalPicker.delegate = self
        self.endIntervalPicker.dataSource = self
        self.endIntervalPicker.delegate = self
        self.trainingFrequencyPicker.dataSource = self
        self.trainingFrequencyPicker.delegate = self
        self.monitoringFrequencyPicker.dataSource = self
        self.monitoringFrequencyPicker.delegate = self
        self.notificationPicker.dataSource = self
        self.notificationPicker.delegate = self
        
        var startInterval = 9
        var endInterval = 22
        var monitorFrequency = 2
        var trainFrequency = 1
        var notifyFrequency = 1
        
        if (defaults?.bool(forKey: "startSet"))! {
            startInterval = (defaults?.integer(forKey: "startInterval"))!
        }
        
        if (defaults?.bool(forKey: "endSet"))! {
            endInterval = (defaults?.integer(forKey: "endInterval"))!
        }
        
        if (defaults?.bool(forKey: "monitorSet"))! {
            monitorFrequency = (defaults?.integer(forKey: "monitorFrequency"))!
        }
        
        if (defaults?.bool(forKey: "trainSet"))! {
            trainFrequency = (defaults?.integer(forKey: "trainFrequency"))!
        }
        
        if (defaults?.bool(forKey: "notifySet"))! {
            notifyFrequency = (defaults?.integer(forKey: "notifyFrequency"))!
        }
        
        self.startIntervalPicker.selectRow(startInterval, inComponent: 0, animated: true)
        self.endIntervalPicker.selectRow(endInterval, inComponent: 0, animated: true)
        self.monitoringFrequencyPicker.selectRow(monitorFrequency, inComponent: 0, animated: true)
        self.trainingFrequencyPicker.selectRow(trainFrequency, inComponent: 0, animated: true)
        self.notificationPicker.selectRow(notifyFrequency, inComponent: 0, animated: true)

        // Do any additional setup after loading the view.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return self.pickerHours.count
        case 1:
            return self.pickerHours.count
        case 2:
            return self.pickerMonitorFrequencies.count
        case 3:
            return self.pickerTrainingFrequencies.count
        case 4:
            return self.pickerNotifications.count
        default:
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerString: String
        let pickerLabel = UILabel()
        
        switch pickerView.tag {
        case 0:
            pickerString = pickerHours[row]
        case 1:
            pickerString = pickerHours[row]
        case 2:
            pickerString = pickerMonitorFrequencies[row]
        case 3:
            pickerString = pickerTrainingFrequencies[row]
        case 4:
            pickerString = pickerNotifications[row]
        default:
            pickerString = "Not found"
        }
        
        let myTitle = NSAttributedString(string: pickerString, attributes: [NSFontAttributeName:UIFont(name: "Avenir", size: 20.0)!,NSForegroundColorAttributeName:UIColor.black])
        pickerLabel.attributedText = myTitle
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            defaults?.set(true, forKey: "startSet")
            defaults?.set(row, forKey: "startInterval")
            if row >= (defaults?.integer(forKey: "endInterval"))! {
                let alertController = UIAlertController(title: "Monitoring Interval", message: "\"From\" time must be earlier than \"To\" time.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        case 1:
            defaults?.set(true, forKey: "endSet")
            defaults?.set(row, forKey: "endInterval")
            if (defaults?.integer(forKey: "startInterval"))! >= row {
                let alertController = UIAlertController(title: "Monitoring Interval", message: "\"From\" time must be earlier than \"To\" time.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        case 2:
            defaults?.set(true, forKey: "monitorSet")
            defaults?.set(row, forKey: "monitorFrequency")
        case 3:
            defaults?.set(true, forKey: "trainSet")
            defaults?.set(row, forKey: "trainFrequency")
        case 4:
            defaults?.set(true, forKey: "notifySet")
            defaults?.set(row, forKey: "notifyFrequency")
        default:
            print("error")
        }

    }
    
    func sendWatchData() {
        let startInterval = (defaults?.integer(forKey: "startInterval"))!
        let endInterval = (defaults?.integer(forKey: "endInterval"))!
        let monitorFrequency = (defaults?.integer(forKey: "monitorFrequency"))!
        let trainFrequency = (defaults?.integer(forKey: "trainFrequency"))!
        let notifyFrequency = (defaults?.integer(forKey: "notifyFrequency"))!
    
        let userSettings = [startInterval, endInterval, monitorFrequency, trainFrequency, notifyFrequency]
        let applicationData = ["userSettings": userSettings]
        self.session.transferUserInfo(applicationData)
        print("Data sent to watch")
    }
    
    @IBAction func backPressed(_ sender: Any) {
        sendWatchData()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        sendWatchData()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
