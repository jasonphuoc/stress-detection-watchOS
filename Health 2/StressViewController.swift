//
//  StressViewController.swift
//  
//
//  Created by Jason La on 3/20/17.
//
//

import UIKit
import Foundation
import Charts
import AIToolbox

class StressViewController: UIViewController {
    
    @IBOutlet weak var lineChartView: LineChartView!
    weak var axisFormatDelegate: IAxisValueFormatter?
    var stressSamples = [[Double]]()
    let defaults = UserDefaults(suiteName: "group.com.jasonla-stress")

    override func viewDidLoad() {
        super.viewDidLoad()
        axisFormatDelegate = self
        
        self.stressSamples = defaults?.array(forKey: "stressResults") as! [[Double]]? ?? [[Double]]()
        
        //self.stressSamples =  [[6.6138888888888889, 1.8274757347305173], [6.614583333333333, 1.7389014605549058], [6.6173611111111112, 1.7155182074956807], [6.6187499999999995, 1.7481137180538735], [6.6194444444444445, 1.6747738192979391], [6.6208333333333327, 1.7725603509725183], [6.6222222222222218, 2.2642105093397267], [6.6236111111111109, 1.9627020366764409], [6.6256944444444441, 1.767128973327283], [6.6263888888888891, 1.7834267286063794], [6.6298611111111114, 1.8812132602809586], [6.6312499999999996, 1.7426823404086382], [6.6319444444444446, 1.6856401969318002], [6.6333333333333337, 1.6267863867920871], [6.6340277777777779, 1.6186375091525391], [6.6381944444444443, 1.7761800619548784], [6.6388888888888893, 1.7191379184780404], [6.6402777777777775, 1.6457980197221065], [6.6409722222222225, 1.6560736570804937], [6.6423611111111107, 1.6011582733224949], [6.6430555555555557, 1.7336670752741059], [6.645833333333333, 1.7347304551335256], [6.6472222222222221, 2.0036434172386182], [6.6500000000000004, 2.0362389277968109], [6.6506944444444445, 1.9954945395990695], [6.6548611111111109, 1.7581137081927507], [6.6638888888888888, 1.6603271765181717], [6.6645833333333337, 1.9247145943094661], [6.665972222222222, 1.9654589825072073], [6.666666666666667, 1.9736078601467562]]
        
        var stressLevels = [Double]()
        var time = [Double]()
        for sample in self.stressSamples {
            time.append(sample[0])
            stressLevels.append(sample[1])
        }
        
        setChart(xVals: time, yVals: stressLevels)
    }
    
    func setChart(xVals: [Double], yVals: [Double]) {
        var yValues : [ChartDataEntry] = [ChartDataEntry]()
        
        for i in 0 ..< xVals.count {
            yValues.append(ChartDataEntry(x: xVals[i], y: yVals[i]))
        }
        
        let data = LineChartData()
        let ds = LineChartDataSet(values: yValues, label: "Stress Level")
        ds.drawFilledEnabled = true
        ds.drawCirclesEnabled = false
        data.addDataSet(ds)
        self.lineChartView.data = data
        self.lineChartView.data?.setDrawValues(false)
        self.lineChartView.chartDescription?.text = " "
        //self.lineChartView.leftAxis.drawLabelsEnabled = false
        //self.lineChartView.rightAxis.drawLabelsEnabled = false
        self.lineChartView.xAxis.drawGridLinesEnabled = false
        //self.lineChartView.leftAxis.drawGridLinesEnabled = false
        //self.lineChartView.rightAxis.drawGridLinesEnabled = false
        //self.lineChartView.xAxis.granularity = 0.1
        self.lineChartView.leftAxis.granularity = 0.1
        self.lineChartView.rightAxis.granularity = 0.1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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

// MARK: axisFormatDelegate
extension StressViewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm.ss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
