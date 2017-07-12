//
//  ViewController.swift
//  Health 2
//
//  Created by Jason La on 2/5/17.
//  Copyright © 2017 Jason La. All rights reserved.
//

import UIKit
import Foundation
import WatchConnectivity
import Charts
import AIToolbox

class ViewController: UIViewController, WCSessionDelegate {
    
    var stressResults = [[Double]]()
    var session: WCSession!
    var learningStressSamples = [[Int]]()
    var stressSamples = [[Int]]()
    let defaults = UserDefaults(suiteName: "group.com.jasonla-stress")
    let features = ["day", "weekday", "time", "restingHR", "hr", "hrDiff", "avgHourlyStepCountWeek", "avgHourlyStepCountDay", "lastHourStepCount"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self;
            session.activate()
        }
        
        self.stressResults = defaults?.array(forKey: "stressResults") as! [[Double]]? ?? [[Double]]()
        //print("Predictions: \(self.stressResults)")
        self.learningStressSamples = defaults?.array(forKey: "learningStressSamples") as! [[Int]]? ?? [[Int]]()
        //defaults?.set(nil, forKey: "stressResults")
        print("Num training samples: \(self.learningStressSamples.count)")
        self.stressSamples = defaults?.array(forKey: "stressSamples") as! [[Int]]? ?? [[Int]]()
        //testStress(sample: [80, 100])
        
        /*
        ///////////TESTING/////////////////
        
        let shuffledSamples = self.learningStressSamples.shuffled()
        let validationSet = Array(shuffledSamples.prefix(Int(Double(shuffledSamples.count) * 0.8)))
        let testSet = Array(shuffledSamples.suffix(Int(Double(shuffledSamples.count) * 0.2)))

        ///////////SINGLE FEATURES/////////
         
        var errors: [String: Double] = [:]
        for i in 0...(self.features.count - 1) {
            let error = nFoldValidation(samples: validationSet, indices: [i], n: 15)
            errors[self.features[i]] = error
            print("Feature: \(self.features[i]), error: \(error)")
        }
        
        let sortedErrors = errors.sorted{ $0.1 > $1.1 }
        print(sortedErrors)
        
        defaults?.set(validationSet, forKey: "validationSet")
        defaults?.set(testSet, forKey: "testSet")
        
        
        [(key: "avgHourlyStepCountWeek", value: 0.77995651212681449), (key: "time", value: 0.73191564175360491), (key: "lastHourStepCount", value: 0.73183007996980953), (key: "day", value: 0.72014202339448063), (key: "weekday", value: 0.71098749274503759), (key: "restingHR", value: 0.69972258538806442), (key: "avgHourlyStepCountDay", value: 0.6907828240088878), (key: "hr", value: 0.68831027429781266), (key: "hrDiff", value: 0.68013920278327022)]
 
        //////////FEATURE GROUPS////////////
         
        let validationSet = defaults?.array(forKey: "validationSet") as! [[Int]]
        
        var indices = [[Int]]()
        for i in 0...(self.features.count - 1) {
            var subIndices = [Int]()
            for j in 0...i {
                subIndices.append(j)
            }
            indices.append(subIndices)
        }
        
        for index in indices {
            let error = nFoldValidation(samples: validationSet, indices: index, n: 15)
            print("Indices: \(index), error: \(error)")
        }
        
         Indices: [0], error: 0.707333487341601
         Indices: [0, 1], error: 0.754454382428694
         Indices: [0, 1, 2], error: 0.702093524580423
         Indices: [0, 1, 2, 3], error: 0.703882549496972
         Indices: [0, 1, 2, 3, 4], error: 0.642856566345641 <!----- BEST
         Indices: [0, 1, 2, 3, 4, 5], error: 0.724963019647667
         Indices: [0, 1, 2, 3, 4, 5, 6], error: 0.698633488736136
         Indices: [0, 1, 2, 3, 4, 5, 6, 7], error: 0.733458827154838
         Indices: [0, 1, 2, 3, 4, 5, 6, 7, 8], error: 0.722140421878855
        
        //////////////TESTING////////////////
        */
        
        let trainSet = defaults?.array(forKey: "validationSet") as! [[Int]]
        let testSet = defaults?.array(forKey: "testSet") as! [[Int]]
        
        var totalError = 0.0
        for item in testSet {
            totalError += testStress2(train: trainSet, sample: item)
            print("Stop")
        }
        
        print("Total error: \(totalError)")
        /*
        Extracted data [20.0, 84.0, 177.0, 64.0, 5.0, 2.0]
        Prediction: 1.375, target: 2.0, error: -0.625
        Extracted data [34.0, 106.0, 127.0, 72.0, 6.0, 3.0]
        Prediction: 1.75, target: 3.0, error: -1.25
        Extracted data [35.0, 101.0, 151.0, 66.0, 6.0, 0.0]
        Prediction: 1.25, target: 0.0, error: 1.25
        Extracted data [28.0, 100.0, 187.0, 72.0, 6.0, 1.0]
        Prediction: 1.375, target: 1.0, error: 0.375
        Extracted data [27.0, 93.0, 151.0, 66.0, 6.0, 0.0]
        Prediction: 1.375, target: 0.0, error: 1.375
        Extracted data [12.0, 91.0, 149.0, 79.0, 6.0, 3.0]
        Prediction: 1.1875, target: 3.0, error: -1.8125
        Extracted data [1.0, 77.0, 167.0, 76.0, 6.0, 1.0]
        Prediction: 1.4609375, target: 1.0, error: 0.4609375
        Extracted data [37.0, 123.0, 1039.0, 86.0, 7.0, 1.0]
        Prediction: 0.5, target: 1.0, error: -0.5
        Extracted data [12.0, 99.0, 69.0, 87.0, 2.0, 3.0]
        Prediction: 2.5625, target: 3.0, error: -0.4375
        Extracted data [54.0, 102.0, 115.0, 48.0, 4.0, 3.0]
        Prediction: 2.5, target: 3.0, error: -0.5
        Extracted data [9.0, 96.0, 75.0, 87.0, 2.0, 2.0]
        Prediction: 2.75, target: 2.0, error: 0.75
        Extracted data [16.0, 88.0, 194.0, 72.0, 6.0, 1.0]
        Prediction: 1.625, target: 1.0, error: 0.625
        Extracted data [65.0, 137.0, 145.0, 72.0, 6.0, 2.0]
        Prediction: 2.0, target: 2.0, error: 0.0
        Extracted data [14.0, 90.0, 151.0, 76.0, 6.0, 0.0]
        Prediction: 1.375, target: 0.0, error: 1.375
        Extracted data [9.0, 96.0, 75.0, 87.0, 2.0, 2.0]
        Prediction: 2.75, target: 2.0, error: 0.75
        Extracted data [55.0, 103.0, 153.0, 48.0, 4.0, 2.0]
        Prediction: 2.5, target: 2.0, error: 0.5
        Extracted data [7.0, 89.0, 398.0, 82.0, 3.0, 2.0]
        Prediction: 1.96875, target: 2.0, error: -0.03125
        Extracted data [24.0, 88.0, 206.0, 64.0, 5.0, 1.0]
        Prediction: 1.75, target: 1.0, error: 0.75
        Extracted data [12.0, 94.0, 396.0, 82.0, 3.0, 3.0]
        Prediction: 2.0, target: 3.0, error: -1.0
        Extracted data [18.0, 102.0, 270.0, 84.0, 5.0, 2.0]
        Prediction: 1.5, target: 2.0, error: -0.5
        Extracted data [44.0, 130.0, 974.0, 86.0, 7.0, 1.0]
        Prediction: 1.25, target: 1.0, error: 0.25
        Extracted data [32.0, 114.0, 398.0, 82.0, 3.0, 3.0]
        Prediction: 2.75, target: 3.0, error: -0.25
        Extracted data [26.0, 74.0, 57.0, 48.0, 4.0, 1.0]
        Prediction: 1.75, target: 1.0, error: 0.75
        Total error: 16.1171875
        */
    }
    
    func nFoldValidation(samples: [[Int]], indices: [Int], n: Int) -> Double {
        var error = 0.0
        
        for _ in 1...n {
            let shuffledSamples = samples.shuffled()
            let rawTrainSet = Array(shuffledSamples.prefix(Int(Double(shuffledSamples.count) * 0.8)))
            let trainSet = processSamples(samples: rawTrainSet)
            
            let rawValidationSet = Array(shuffledSamples.suffix(Int(Double(shuffledSamples.count) * 0.2)))
            let validationSet = processSamples(samples: rawValidationSet)
            let e = testModelFeatureMult(train: trainSet, validation: validationSet, indexes: indices)
            //print("Error: \(e)")
            error += e
        }
        
        return error / Double(n)
    }
    
    func testModelFeatureMult(train: [[Double]], validation: [[Double]], indexes: [Int]) -> Double {
        let processedTrain = selectFeatures(samples: train, indices: indexes)
        //print(processedTrain)
        let testModel = getTestModelMult(samples: processedTrain)
        
        let processedValidation = selectFeatures(samples: validation, indices: indexes)
        //print(processedValidation)
        
        return testFeatureMult(model: testModel, samples: processedValidation)
    }
    
    /*
    func testModelFeature(train: [[Double]], validation: [[Double]], index: Int) -> Double {
        let testModel = getTestModel(samples: train, featureIndex: index)
        return testFeature(model: testModel, samples: validation, featureIndex: index)
    }*/
    
    func testFeatureMult(model: LinearRegressionModel, samples: [[Double]]) -> Double {
        var totalError = 0.0
        
        //print("Feature data: \(samples)")
        for sample in samples {
            do {
                let prediction = try model.predictOne(Array(sample.prefix(sample.count - 1)))
                let error = pow(sample[sample.count - 1] - prediction[0], 2)
                totalError += error
                //print("Prediction: \(prediction), Target: \(sample[8])")
            } catch {
                print("Prediction error")
            }
        }
        
        return (totalError / Double(samples.count)).squareRoot()
    }
    /*
    func testFeature(model: LinearRegressionModel, samples: [[Double]], featureIndex: Int) -> Double {
        var totalError = 0.0
        
        for sample in samples {
            do {
                let prediction = try model.predictOne([sample[featureIndex]])
                let error = pow(sample[sample.count - 1] - prediction[0], 2)
                totalError += error
                //print("Prediction: \(prediction), Target: \(sample[8])")
            } catch {
                print("Prediction error")
            }
        }
        
        return (totalError / Double(samples.count)).squareRoot()
    }*/
    
    func processSamples(samples: [[Int]]) -> [[Double]] {
        var processedSamples = [[Double]]()
        
        for sample in samples {
            let day = Double(sample[2])
            let weekday = Double(sample[3])
            let time = Double(sample[4]) + Double(sample[5]) / 60.0
            let restingHR = Double(sample[6])
            let hr = Double(sample[7])
            let hrDiff = hr - restingHR
            let avgHourlyStepCountWeek = Double(sample[8]) / 24.0
            let avgHourlyStepCountDay = Double(sample[9])
            let lastHourStepCount = Double(sample[10])
            let target = Double(sample[11])
            
            //let features = [day, weekday, time, restingHR, hr, hrDiff, avgHourlyStepCountWeek, avgHourlyStepCountDay, lastHourStepCount, target]
            let sortedFeatures = [hrDiff, hr, avgHourlyStepCountDay, restingHR, weekday, day, lastHourStepCount, time, avgHourlyStepCountWeek, target]
            //print(features)
            processedSamples.append(sortedFeatures)
        }
        
        return processedSamples
    }
    
    func selectFeatures(samples: [[Double]], indices: [Int]) -> [[Double]] {
        var ret = [[Double]]()
        var indexes = indices
        indexes.append(9)
        for sample in samples {
            var row = [Double]()
            for index in indexes {
                row.append(sample[index])
            }
            ret.append(row)
        }
        return ret
    }
    
    func getTestModelMult(samples: [[Double]]) -> LinearRegressionModel {
        //print("Dimension: \(samples[0].count - 1)")
        let trainData = DataSet(dataType: .regression, inputDimension: samples[0].count - 1, outputDimension: 1)
        
        for sample in samples {
            do {
                //print("Input: \(Array(sample.prefix(sample.count - 1))), output: \(sample[sample.count - 1]))")
                try trainData.addDataPoint(input: Array(sample.prefix(sample.count - 1)), output: [sample[sample.count - 1]])
            } catch {
                print("error adding training data")
            }
        }
        
        let lr = LinearRegressionModel(inputSize: samples[0].count - 1, outputSize: 1, polygonOrder: 1)
        
        do {
            try lr.trainRegressor(trainData)
        } catch {
            print("Linear Regression Training error")
        }
        
        return lr
    }
    
    /*
    func getTestModel(samples: [[Double]], featureIndex: Int) -> LinearRegressionModel {
        let trainData = DataSet(dataType: .regression, inputDimension: 1, outputDimension: 1)
        
        for sample in samples {
            do {
                try trainData.addDataPoint(input: [sample[featureIndex]], output: [sample[sample.count - 1]])
            } catch {
                print("error adding training data")
            }
        }
        
        let lr = LinearRegressionModel(inputSize: 1, outputSize: 1, polygonOrder: 1)
        
        do {
            try lr.trainRegressor(trainData)
        } catch {
            print("Linear Regression Training error")
        }
        
        return lr
    }*/
    
    /*
    func train() -> LinearRegressionModel {
        let trainData = DataSet(dataType: .regression, inputDimension: 3, outputDimension: 1)
        
        var heartRates = [Double]()
        var restingRates = [Double]()
        
        for sample in self.learningStressSamples {
            let day = Double(sample[2])
            let weekday = Double(sample[3])
            let time = Double(sample[4]) + Double(sample[5]) / 60.0
            let restingHR = Double(sample[6])
            let hr = Double(sample[7])
            let avgHourlyStepCountWeek = Double(sample[8]) / 24.0
            let avgHourlyStepCountDay = Double(sample[9])
            let lastHourStepCount = Double(sample[10])
            let target = Double(sample[11])
            let hrDiff = hr - restingHR
            
            //print(day, weekday, time, restingHR, hr, avgHourlyStepCountWeek, avgHourlyStepCountDay, lastHourStepCount, hrDiff)
            //print(target)
            
            do {
                try trainData.addDataPoint(input: [restingHR, hr, hrDiff], output: [target])
            } catch {
                print("error adding training data")
            }
            
            heartRates.append(hr)
            restingRates.append(restingHR)
        }
        
        let avgHR = heartRates.reduce(0, +) / Double(heartRates.count)
        let avgRestingHR = restingRates.reduce(0, +) / Double(restingRates.count)
        
        print("Average HR: \(avgHR)")
        print("Average resting HR: \(avgRestingHR)")
        
        let lr = LinearRegressionModel(inputSize: 3, outputSize: 1, polygonOrder: 1)
        
        do {
            try lr.trainRegressor(trainData)
        } catch {
            print("Linear Regression Training error")
        }
        
        return lr
    }*/
    
    func testStress2(train: [[Int]], sample: [Int]) -> Double {
        let ind = [0, 1, 2, 3, 4]
        let processedTrainingData = processSamples(samples: train)
        let extractedFeatures = selectFeatures(samples: processedTrainingData, indices: ind)
        
        for sample in extractedFeatures {
            print(sample[5])
        }
        
        let model = getTestModelMult(samples: extractedFeatures)
        
        let processedStressData = processSamples(samples: [sample])
        var extractedStressData = selectFeatures(samples: processedStressData, indices: ind)
        //print("Sample data \(extractedStressData[0])")
        let data = Array(extractedStressData[0].prefix(5))
        let target = Double(Array(extractedStressData[0].suffix(1))[0])
        var absError = 0.0

        do {
            let result = try model.predictOne(data)
            let prediction = result[0]
            let error = prediction - target
            absError = abs(error)
            //print(target)
        } catch {
            print("Error calculating prediction")
        }
        
        return absError
    }

    func testStress(sample: [Int]) {
        let day = Double(sample[2])
        let hour = Double(sample[4])
        let minute = Double(sample[5])
        let ind = [0, 1, 2, 3, 4]
        
        let processedTrainingData = processSamples(samples: self.learningStressSamples)
        let extractedFeatures = selectFeatures(samples: processedTrainingData, indices: ind)
        let model = getTestModelMult(samples: extractedFeatures)
        
        let processedStressData = processSamples(samples: [sample])
        var extractedStressData = selectFeatures(samples: processedStressData, indices: ind)
        
        do {
            let result = try model.predictOne(extractedStressData[0])
            let time = day + hour / 24 + minute / (24 * 60)
            let predictionEntry = [time, result[0]]
            self.stressResults.append(predictionEntry)
            defaults?.set(self.stressResults, forKey: "stressResults")
            
            sendWatchData(prediction: result[0])
            print("Time, Result: \(predictionEntry)")
            print("Stress results: \(self.stressResults)")
        } catch {
            print("Error calculating prediction")
        }
    }
    
    func sendWatchData(prediction: Double) {
        let applicationData = ["prediction": prediction]
        self.session.transferUserInfo(applicationData)
        print("Prediction sent to watch")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("received data")
        for key in userInfo.keys {
            switch key {
            case "learningStressSamples":
                print("Got learning stress sample")
                self.learningStressSamples = userInfo["learningStressSamples"] as! [[Int]]
                self.defaults?.set(self.learningStressSamples, forKey: "learningStressSamples")
                print(self.learningStressSamples)
            case "stressSample":
                print("Got stress sample")
                var stressSample = userInfo["stressSample"] as! [Int]
                stressSample.append(0)
                testStress(sample: stressSample)
                self.stressSamples.append(stressSample)
                defaults?.set(self.stressSamples, forKey: "stressSamples")
            default:
                print("error")
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

