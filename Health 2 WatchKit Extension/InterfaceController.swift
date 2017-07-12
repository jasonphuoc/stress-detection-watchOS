//
//  InterfaceController.swift
//  Health 2 WatchKit Extension
//
//  Created by Jason La on 2/5/17.
//  Copyright © 2017 Jason La. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import CoreMotion
import UserNotifications
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {

    @IBOutlet var stressLevelLabel: WKInterfaceLabel!
    @IBOutlet var stressLevelPicker: WKInterfacePicker!
    @IBOutlet var homeGroup: WKInterfaceGroup!
    @IBOutlet var stressCheckinGroup: WKInterfaceGroup!
    @IBOutlet var breatheLabel: WKInterfaceLabel!
    @IBOutlet var onButton: WKInterfaceButton!
    @IBOutlet var stressIndicator: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!

    var stressMonitoringOn = false
    var startTime = 24
    var endTime = 0
    var isTesting = false
    var prediction = 0.0
    var userSettings = [Int]()
    var lastHourStepCount = 0
    var avgHourlyStepCountWeek = 0
    var avgHourlyStepCountDay = 0
    var learningStressLevel = 3
    var stressLevel = 0
    var isInForeground = true
    let wcSession = WCSession.default()
    let defaults = UserDefaults(suiteName: "group.com.jasonla-stress")
    var hrSampleAvgs = [Int]()
    var hrCountAvg = 0
    let healthStore = HKHealthStore()
    var workoutActive = false
    var session: HKWorkoutSession?
    let heartRateUnit = HKUnit(from: "count/min")
    var currentQuery: HKQuery?
    let stressThreshold: Double = 0.5 //let user adjust this parameter
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    var isActive: Bool = true
    var activity = 0
    var confidence = 0
    var stressSampling = 0
    var HRSamples = [Int]()
    var learningStressSamples = [[Int]]()
    var activitySamples = [Int]()
    let window = 60 * 1 // complete window for HR samples in seconds
    var sampleWindow = 0
    weak var timer: Timer?
    weak var timer2: Timer?
    weak var timer3: Timer?
    weak var timer4: Timer?
    weak var timer5: Timer?
    weak var timer6: Timer?
    weak var timer7: Timer?
    weak var timer8: Timer?
    weak var timer9: Timer?
    weak var timer10: Timer?
    var pastWeek = 0
    var pastThreeMonths = 0
    var counter = 0
    var stressTriggered = false
    var restingHR = 0
    var breatheNotificationOn = false
    var bgColor = UIColor.black
    var itemList: [(Int, String)] = [
        (0, "Relaxed"),
        (1, "Not Stressed"),
        (2, "Slightly stressed"),
        (3, "Stressed"),
        (4, "Very stressed")]
    
    @IBAction func onButtonPressed() {
        if self.learningStressSamples.count < 50 {
            let h0 = { print("OK")}
            let action1 = WKAlertAction(title: "OK", style: .default, handler: h0)
            presentAlert(withTitle: "Alert", message: "Not enough training samples.", preferredStyle: .actionSheet, actions: [action1])
        } else {
            if(self.isTesting == false) {
                self.isTesting = true
                self.statusLabel.setHidden(false)
                callTestStress()
            }
        }
    }
    
    @IBAction func stressOn() {
        if(stressSampling == 0) {
            stressSampling = 1
            hideStressLabels()
            self.statusLabel.setHidden(false)
            self.statusLabel.setText("Sampling...")
            //sampleButton.setTitle("Stress off")
            //getStressSample(repeats: false)
            //breatheMessage()
            unhidePicker()
        } else {
            //stressSampling = 0
            //sampleButton.setTitle("Stress on")
        }
    }
    
    func startMonitor() {
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.window / 2), target: self, selector: #selector(InterfaceController.compareHeartRate), userInfo: nil, repeats: true)
    }
    
    func stopMonitor() {
        if timer != nil {
            timer?.invalidate()
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Invalid state")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error){
        print("Workout session error")
    }
    
    func workoutDidStart(_ date: Date) {
        if let query = createHeartRateStreamingQuery(date){
            currentQuery = query
            healthStore.execute(query)
        } else {
            //stressLevelLabel.setText("Not available")
        }
    }
    
    func workoutDidEnd(_ date: Date){
        healthStore.stop(self.currentQuery!)
        //stressLevelLabel.setText("- - -")
        session = nil
    }
    
    func startWorkOut() {
        self.workoutActive = true
        
        if(session != nil) {
            return
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .mindAndBody
        workoutConfiguration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
            fatalError("Unable to create workout session.")
        }
        
        healthStore.start(session!)
    }
    
    func endWorkout() {
        self.workoutActive = false
        if let workout = session {
            healthStore.end(workout)
        }
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else {
                return
            }
            
            let heartRateDouble = sample.quantity.doubleValue(for: self.heartRateUnit)
            let heartRateInteger = Int(heartRateDouble)
            self.HRSamples.append(heartRateInteger)
            self.getActivity()
            
            let d = Date()
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:m:ss.SS"
            
            print("\(heartRateInteger),\(self.stressSampling),\(self.activity),\(self.confidence),\(df.string(from: d))")
        }
    }

    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            return nil
        }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate])
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            self.updateHeartRate(sampleObjects)
        }
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }

    func compareHeartRate() {/*
        if self.HRSamples.count > self.sampleWindow * 2 {
            counter += 1
            let HRWindow = self.HRSamples.suffix(self.sampleWindow * 2)
            let firstHalf = HRWindow.prefix(self.sampleWindow)
            let secondHalf = HRWindow.suffix(self.sampleWindow)
            
            let activityWindow = self.activitySamples.suffix(self.sampleWindow * 2)
            
            let firstHalfTotal = firstHalf.reduce(0, +)
            let secondHalfTotal = secondHalf.reduce(0, +)
            let activityTotal = activityWindow.reduce(0, +)
            //let HRWindowTotal = HRWindow.reduce(0, +)
            
            let firstHalfAvg = firstHalfTotal / self.sampleWindow
            let secondHalfAvg = secondHalfTotal / self.sampleWindow
            let activityAvg = Double(activityTotal) / Double((self.sampleWindow * 2))
            //let HRWindowAvg = HRWindowTotal / self.sampleWindow * 2
            
            //print("Second half total: \(secondHalfTotal), avg: \(secondHalfAvg)")
            let d = Date()
            let calendar = Calendar.current
            let year = calendar.component(.year, from: d)
            let month = calendar.component(.month, from: d)
            let day = calendar.component(.day, from: d)
            let hour = calendar.component(.hour, from: d)
            let minute = calendar.component(.minute, from: d)
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:m:ss.SS"
            
            if activityAvg < 1.5 {
                self.hrSampleAvgs.append(secondHalfAvg)
                //let hrSampleAvgsTotal = hrSampleAvgs.reduce(0, +)
                //self.hrCountAvg = hrSampleAvgsTotal / self.hrSampleAvgs.count
                //print("Heart rate counts: \(self.hrSampleAvgs)")
  
                let hrChange = secondHalfAvg - firstHalfAvg
                //let hrAboveAvg = secondHalfAvg - self.hrCountAvg
                let hrAboveResting = (secondHalfAvg - self.restingHR)
                
                let figures = [hrChange, /*hrAboveAvg,*/ hrAboveResting / 2]
                var diff = Double(figures.max()!)
                if diff < 0.0 { diff = 0.0 }
                
                var stressLevel = diff / 20
                if stressLevel > 1 { stressLevel = 1.0 }
                //self.learningStressSamples.append("\(year) \(month) \(day) \(hour) \(minute) \(stressLevel)")
                
                if stressTriggered == false && (stressLevel > self.stressThreshold) {
                    print("\(df.string(from: d)): Stressed")
                    if self.isInForeground == true {
                        breatheMessage()
                    } else {
                        stressNotification()
                    }
                } else {
                    print("\(df.string(from: d)): Not stressed")
                }
                
                var redness = (diff * 15.0) / 255.0
                if redness < 0.0 { redness = 0.0 }
                if redness > 1.0 { redness = 1.0 }
                
                var blueness = (255 - diff * 15.0) / 255.0
                if blueness < 0.0 { blueness = 0.0 }
                if blueness > 1.0 { blueness = 1.0 }
                
                //print("red: \(redness), blue: \(blueness)")
                self.bgColor = UIColor(red: CGFloat(redness), green: 0, blue: CGFloat(blueness), alpha: 1)
                if self.breatheNotificationOn == false {
                    self.stressIndicator.setBackgroundColor(self.bgColor)
                }
                
                print("Current avg heart rate: \(secondHalfAvg), \(secondHalf)")
                print("Previous avg heart rate: \(firstHalfAvg), \(firstHalf)")
                print("HR change: \(hrChange)")
                //print("HR above avg: \(hrAboveAvg)")
                print("HR above resting: \(hrAboveResting)")
                print("Stress level: \(stressLevel)")
                //sendDataIOS()
            } else {
                self.stressIndicator.setBackgroundColor(UIColor.green)
            }
        }*/
    }
    
    func getActivity() {
        if(CMMotionActivityManager.isActivityAvailable()){
            self.activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: {
                [weak self] (data: CMMotionActivity?) in
                DispatchQueue.main.async(execute: {
                    if let data = data {
                        if data.stationary == true { self?.activity = 0 }
                        else if data.walking == true { self?.activity = 2 }
                        else if data.running == true { self?.activity = 3 }
                        else if data.automotive == true { self?.activity = 4 }
                        else if data.cycling == true { self?.activity = 5 }
                        else { self?.activity = 1 }
                        
                        self?.confidence = data.confidence.rawValue
                    }
                })
            })
        }
        
        self.activitySamples.append(self.activity)
    }
    
    func getStepCounts() {
        let endDate = NSDate()
        let hour = 60 * 60
        let day = hour * 24
        let week = day * 7
        let oneHour = Date(timeInterval: TimeInterval(-hour), since: endDate as Date)
        let oneDay = Date(timeInterval: TimeInterval(-day), since: endDate as Date)
        let oneWeek = Date(timeInterval: TimeInterval(-week), since: endDate as Date)
        
        pedometer.queryPedometerData(from: oneHour, to: endDate as Date, withHandler: { (data, error) in
            if let data = data {
                self.lastHourStepCount = Int(data.numberOfSteps)
                print("Start: \(oneHour) end: \(endDate), count: \(self.lastHourStepCount)")
            }
        })
        
        pedometer.queryPedometerData(from: oneDay, to: endDate as Date, withHandler: { (data, error) in
            if let data = data {
                self.avgHourlyStepCountDay = Int(data.numberOfSteps) / 24
            }
        })
        
        pedometer.queryPedometerData(from: oneWeek, to: endDate as Date, withHandler: { (data, error) in
            if let data = data {
                self.avgHourlyStepCountWeek = Int(data.numberOfSteps) / 7
            }
        })
    }

    
    func resetStressBool() {
        self.stressTriggered = false
    }
    
    func breatheMessage() {
        WKInterfaceDevice.current().play(.notification)
        self.stressIndicator.setBackgroundColor(UIColor.orange)
        self.breatheLabel.setHidden(false)
    }
    
    func endBreatheMsg() {
        print("Cleared breathe message")
        hideStressLabels()
        self.stressIndicator.setBackgroundColor(UIColor.black)
    }
    
    func cancelTraining() {
        if #available(watchOSApplicationExtension 3.0, *) {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
        }
    }
    
    func getStressSample(repeats: Bool) {
        if #available(watchOSApplicationExtension 3.0, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Stress Check-in"
            content.body = "Tap to record stress level."
            content.sound = UNNotificationSound.default()
            content.categoryIdentifier = "stressCategory"
            
            if repeats {
                var totalMins = self.userSettings[0] * 60
                var hours : Int = 0
                var mins : Int = 0
                let date = NSDateComponents()
                let startHour = self.userSettings[0]
                let endHour = self.userSettings[1]
                var interval = self.userSettings[3] * 60
                if interval == 0 { interval = 15 }
                
                while totalMins <= self.userSettings[1] * 60 {
                    hours = totalMins / 60
                    mins = totalMins % 60
                    date.hour = hours
                    date.minute = mins
                    
                    if(hours >= startHour && hours < endHour) || (mins == 0 && hours == endHour){
                        let trigger = UNCalendarNotificationTrigger.init(dateMatching: date as DateComponents, repeats: true)
                        let request = UNNotificationRequest.init(identifier: String(totalMins), content: content, trigger: trigger)
                        center.add(request)
                        print("Stress sample set for hour: \(hours), min: \(mins)")
                    }
                    
                    totalMins += Int(interval)
                }
            } /*else {
                let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 2, repeats: false)
                let id = String(Date().timeIntervalSinceReferenceDate)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request ,withCompletionHandler: nil)
            }(*/
        }
    }
    
    func stressNotification(level: Double) {
        if #available(watchOSApplicationExtension 3.0, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Stress Notification"
            
            if level >= 3.5 {
                content.body = "15 Min Walk"
            } else {
                content.body = "Breathe"
            }
            
            content.sound = UNNotificationSound.default()
            content.categoryIdentifier = "defaultCategory"
            // Deliver the notification in five seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 2, repeats: false)
            let id = String(Date().timeIntervalSinceReferenceDate)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            // Schedule the notification.
            center.add(request ,withCompletionHandler: nil)
        }
        /*
        self.stressTriggered = true
        timer3 = Timer.scheduledTimer(timeInterval: 60.0 * 15, target: self, selector: #selector(InterfaceController.resetStressBool), userInfo: nil, repeats: false)*/
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        print("Heart rate, Stress On, Activity, Confidence, Time")
        //let bgColor = UIColor(red: CGFloat(0.5), green: 0, blue: CGFloat(0.5), alpha: 1)
        //self.stressIndicator.setBackgroundColor(bgColor)
        
        //self.defaults?.set(nil, forKey: "hrSampleAvgs")
        //self.defaults?.set(nil, forKey: "stressSamples")
        
        self.stressLevelLabel.setHidden(true)
        self.statusLabel.setHidden(true)

        self.stressIndicator.setCornerRadius(37)
        self.hrSampleAvgs = defaults?.array(forKey: "hrSampleAvgs") as! [Int]? ?? [Int]()
        self.sampleWindow = self.window / 12
        //defaults?.set(nil, forKey: "learningStressSamples")
        self.learningStressSamples = defaults?.array(forKey: "learningStressSamples") as! [[Int]]? ?? [[Int]]()
        self.stressMonitoringOn = defaults?.bool(forKey: "stressMonitoringOn") ?? false
        self.userSettings = defaults?.array(forKey: "userSettings") as! [Int]? ?? [Int]()
        print("Stress samples: \(self.learningStressSamples.count)")
        //print("HR sample averages: \(self.hrSampleAvgs)")
        
        if self.hrSampleAvgs.count != 0 {
            //let hrSampleAvgsTotal = hrSampleAvgs.reduce(0, +)
            //self.hrCountAvg = hrSampleAvgsTotal / self.hrSampleAvgs.count
            //print("HR count avg: \(self.hrCountAvg), \(self.hrSampleAvgs)")

            setRestingHR()
            print("Resting HR: \(self.restingHR)")
        } else {
            self.restingHR = 80
        }
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            //stressLevelLabel.setText("Not available")
            return
        }
        
        let pickerItems: [WKPickerItem] = self.itemList.map {
            let pickerItem = WKPickerItem()
            pickerItem.caption = $0.1
            pickerItem.title = $0.1
            return pickerItem
        }
        
        self.stressLevelPicker.setItems(pickerItems)
        hidePicker()
        
        if self.learningStressSamples.count > 100 && self.stressMonitoringOn == true {
            self.cancelTraining()
            self.intervalCallStressTest()
            print("Stress monitoring occuring")
        }
        // Configure interface objects here.
    }
    
    func setRestingHR() {
        let recentHRSamples = self.hrSampleAvgs.suffix(12)
        self.restingHR = recentHRSamples.min()!
    }
    
    override func willActivate() {
        super.willActivate()
        
        self.isInForeground = true
        self.wcSession.delegate = self
        self.wcSession.activate()
        
        if self.hrSampleAvgs.count != 0 {
            setRestingHR()
        }
        
        if notificationAppeared == true {
            unhidePicker()
        }
    }
    
    func hidePicker() {
        notificationAppeared = false
        self.stressLevelPicker.resignFocus()
        self.stressCheckinGroup.setHidden(true)
        self.homeGroup.setHidden(false)
    }
    
    func unhidePicker() {
        self.stressLevelPicker.focus()
        self.stressCheckinGroup.setHidden(false)
        self.homeGroup.setHidden(true)
        self.stressLevelPicker.setSelectedItemIndex(1)
    }
    
    @IBAction func donePressed() {
        hidePicker()
        getStepCounts()
        
        if self.workoutActive == false {
            startWorkOut()
            timer5 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.endWorkout), userInfo: nil, repeats: false)
            timer6 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.storeLearningStressSample), userInfo: nil, repeats: false)
        } else {
            timer6 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.storeLearningStressSample), userInfo: nil, repeats: false)
        }
    }
    
    func cancelIntervalStressTest() {
        if timer9 != nil {
            timer9?.invalidate()
        }
    }
    
    func intervalCallStressTest() {
        let interval = self.userSettings[2]
        var timeInterval = 0.0
        switch (interval) {
        case 0:
            timeInterval = 15.0
        case 1:
            timeInterval = 30.0
        default:
            timeInterval = Double((interval - 1) * 60)
        }
        
        print("Time interval: \(timeInterval)")
        //timeInterval = 15.0
        
        self.timer9 = Timer.scheduledTimer(timeInterval: timeInterval * 60, target: self, selector: #selector(InterfaceController.callTestStress), userInfo: nil, repeats: true)

    }
    
    func hideStressLabels() {
        self.breatheLabel.setHidden(true)
        self.stressLevelLabel.setHidden(true)
    }
    
    func unhideStressLabels() {
        self.breatheLabel.setHidden(false)
        self.stressLevelLabel.setHidden(false)
    }
    
    func callTestStress() {
        WKInterfaceDevice.current().play(.notification)
        hideStressLabels()
        self.statusLabel.setHidden(false)
        self.statusLabel.setText("Testing...")
        let d = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: d)
        
        if hour >= self.userSettings[0] && hour < self.userSettings[1] {
            print("Checking stress")
            getStepCounts()
            if self.workoutActive == false {
                startWorkOut()
                
                self.timer7 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.endWorkout), userInfo: nil, repeats: false)
                self.timer8 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.testStress), userInfo: nil, repeats: false)
            
            } else {
                self.timer8 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.testStress), userInfo: nil, repeats: false)
                
            }
        }
    }
    
    func testStress() {
        let d = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: d)
        let month = calendar.component(.month, from: d)
        let day = calendar.component(.day, from: d)
        let hour = calendar.component(.hour, from: d)
        let minute = calendar.component(.minute, from: d)
        let weekDay = calendar.component(.weekday, from: d)
        
        let lastTenSamples = self.HRSamples.suffix(10)
        print(lastTenSamples)
        let avgHR = lastTenSamples.reduce(0, +) / lastTenSamples.count
        self.hrSampleAvgs.append(avgHR)
        
        let stressSample = [year, month, day, weekDay, hour, minute, self.restingHR, avgHR, self.avgHourlyStepCountWeek, self.avgHourlyStepCountDay, self.lastHourStepCount]
        sendDataIOS(key: "stressSample", value: stressSample)
        self.isTesting = false
        self.statusLabel.setHidden(true)
    }

    func storeLearningStressSample() {
        var learningStressSamples = self.defaults?.array(forKey: "learningStressSamples") as? [[Int]] ?? [[Int]]()
        
        let d = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: d)
        let month = calendar.component(.month, from: d)
        let day = calendar.component(.day, from: d)
        let hour = calendar.component(.hour, from: d)
        let minute = calendar.component(.minute, from: d)
        let weekDay = calendar.component(.weekday, from: d)
        
        let lastTenSamples = self.HRSamples.suffix(10)
        print(lastTenSamples)
        let avgHR = lastTenSamples.reduce(0, +) / lastTenSamples.count
        self.hrSampleAvgs.append(avgHR)
        
        let learningStressSample = [year, month, day, weekDay, hour, minute, self.restingHR, avgHR, self.avgHourlyStepCountWeek, self.avgHourlyStepCountDay, self.lastHourStepCount, self.learningStressLevel]
        learningStressSamples.append(learningStressSample)
        self.defaults?.set(learningStressSamples, forKey: "learningStressSamples")

        print(learningStressSample)
        //if learningStressSamples.count > 50 {
        sendDataIOS(key: "learningStressSamples", value: learningStressSamples)
        //}
        
        print(learningStressSamples.count)
        self.stressSampling = 0
        self.statusLabel.setHidden(true)
    }
    
    func sendDataIOS(key: String, value: Any) {
        let applicationData = [key: value]
        self.wcSession.transferUserInfo(applicationData)
        print("Data sent to phone")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        for key in userInfo.keys {
            switch key {
            case "userSettings":
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                
                self.userSettings = userInfo["userSettings"] as! [Int]
                defaults?.set(self.userSettings, forKey: "userSettings")
                print("Data received: \(self.userSettings)")
                
                if self.learningStressSamples.count < 100 {
                    getStressSample(repeats: true)
                }
                
                self.stressMonitoringOn = true
                defaults?.set(true, forKey: "stressMonitoringOn")
                //self.cancelIntervalStressTest()
                self.intervalCallStressTest()
            case "prediction":
                self.prediction = userInfo["prediction"] as! Double
                var label = ""
                var actionLabel = ""
                
                if self.prediction < 0.5 {
                    label = "Relaxed"
                } else if self.prediction < 1.5 {
                    label = "Not Stressed"
                } else if self.prediction < 2.5 {
                    breatheMessage()
                    stressNotification(level: self.prediction)
                    label = "Bit Stressed"
                    actionLabel = "Breathe"
                } else if self.prediction < 3.5 {
                    breatheMessage()
                    stressNotification(level: self.prediction)
                    label = "Stressed"
                    actionLabel = "Breathe"
                } else {
                    breatheMessage()
                    stressNotification(level: self.prediction)
                    label = "Very Stressed"
                    actionLabel = "15 Min Walk"
                }
                self.breatheLabel.setText(actionLabel)
                self.stressLevelLabel.setText(label)
                self.stressLevelLabel.setHidden(false)
                
                DispatchQueue.main.async {
                    self.timer4 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(InterfaceController.endBreatheMsg), userInfo: nil, repeats: false)
                }
                
            default:
                print("error")
            }
        }
    }

    @IBAction func pickerChanged(_ value: Int) {
        self.learningStressLevel = itemList[value].0
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        self.isInForeground = false
        self.defaults?.set(self.hrSampleAvgs, forKey: "hrSampleAvgs")
        self.defaults?.set(self.learningStressSamples, forKey: "stressSamples")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    

}
