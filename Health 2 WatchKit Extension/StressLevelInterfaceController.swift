//
//  StressLevelInterfaceController.swift
//  Health 2
//
//  Created by Jason La on 3/24/17.
//  Copyright © 2017 Jason La. All rights reserved.
//

import WatchKit
import Foundation


class StressLevelInterfaceController: WKInterfaceController {

    @IBOutlet var stressLevelPicker: WKInterfacePicker!
    var stressLevel = 0
    
    var itemList: [(Int, String)] = [
        (1, "Very stressed"),
        (2, "Stressed"),
        (3, "Slightly stressed"),
        (4, "Not stressed"),
        (5, "Relaxed")]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let pickerItems: [WKPickerItem] = itemList.map {
            let pickerItem = WKPickerItem()
            pickerItem.caption = $0.1
            pickerItem.title = $0.1
            return pickerItem
        }
        
        self.stressLevelPicker.setItems(pickerItems)
        self.stressLevelPicker.setSelectedItemIndex(3)
        
        // Configure interface objects here.
    }

    @IBAction func pickerChanged(_ value: Int) {
        self.stressLevel = itemList[value].0
    }
    
    @IBAction func donePressed() {
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
