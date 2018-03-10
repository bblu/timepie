//
//  TodoPicker.swift
//  TimePie
//
//  Created by lu wenbo on 10/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

class TodoPickerDsDelegate:NSObject,UIPickerViewDataSource,UIPickerViewDelegate
{
    var data:[Int:String] = [:]
    let comNum = [0:7,1:4,2:4]
    
    init(items:[TodoItem]){
        for item in items{
            data[item.code] = item.alias
            //print("\(item.code) : \(item.alias)")
        }
    }
    var selectionUpdated: ((_ component: Int,_ row: Int) -> Void)?
    //*UIPickerViewDataSource
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int{
        print("returns the number of 'columns' to display")
        return 2
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        print("returns the # of rows in each component..")
        return comNum[component]!
    }
    // UIPickerViewDelegate
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        print("returns width of row for each component")
        return 200
    }
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{
        print("returns height of row for each component")
        return 120
    }
    
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        print("pickerView.titleForRow.delegate")
        let idx = component * 10 + row
        return "data[idx]"
    }
    
    //public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    // attributed title is favored if both methods are implemented
    //public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        print("selectionUpdated")
        //selectionUpdated?(component, row)
    }
}
