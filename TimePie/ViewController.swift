//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    //------------------------------------------------------------------------------
    @IBOutlet weak var curText: UITextField!
    @IBOutlet weak var curLabel: UILabel!
    let inputMode = 1
    var picker = UIPickerView()
    //------------------------------------------------------------------------------
    //*UIPickerViewDataSource
    var data:[Int:String] = [:]
    let comNum = [0:7,1:4]
    public func numberOfComponents(in pickerView: UIPickerView) -> Int{
        print("returns the number of 'columns[2]' to display")
        return 2
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        print("returns the number[\(comNum[component]!)] of rows in each component[\(component)]")
        return comNum[component]!
    }
    // UIPickerViewDelegate
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        //print("returns width of row for each component")
        return 100
    }
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{
        //print("returns height of row for each component")
        return 35
    }
    
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        let select0 = picker.selectedRow(inComponent: 0)
        if component == 0{
            print("pickerView.delegate.titleForRow0[select0=\(select0),com=\(component),row=\(row),index=\((row + 1) * 10)]")
            return data[(row + 1) * 10]
        }
        let idx = (select0 + 1) * 10 + component * row
        print("pickerView.delegate.titleForRow1[select0=\(select0),com=\(component),row=\(row),index=\(idx)]")
        return data[idx]
    }
    //public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    // attributed title is favored if both methods are implemented
    //public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        if(component==0){
            picker.reloadComponent(1)
        }
        let select0 = picker.selectedRow(inComponent: 0)
        let idx = (select0 + 1) * 10 + component * row
        print("pickerView.delegate.didSelectRow[select0=\(select0),com=\(component),row=\(row)],index=\(idx)")

        curLabel.text = data[idx]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initInputCtrl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initInputCtrl(){
        if let path = Bundle.main.path(forResource: "actions", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let todoConfig = try decoder.decode(TodoConfig.self, from: data)
                print(todoConfig.user)
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    print("addPicker...")
                    addPickerView(items: todoConfig.items)
                }
            } catch {
                print("error:\(error)")                // handle error
            }
        }
    }
    func addPickerView(items:[TodoItem]){
        for item in items{
            data[item.code] = item.alias
            print("\(item.code) : \(item.alias)")
        }
        //let dsDelegate = TodoPickerDsDelegate(items:items)
        picker.dataSource = self
        picker.delegate = self
        picker.center = self.view.center
        self.view.addSubview(picker)
        //picker.reloadAllComponents()
        print("...addPicker")
    }
    func addButtons(items:[TodoItem]){
        for item in items{
            let pos = item.code
            //pos: 10,11,12,13,14
            //     20,21,22,23,24
            let px = (pos % 10) * 80
            let py = 400 + (pos / 10) * 50
            let btnItem = UIButton(frame: CGRect(x:px, y: py, width: 80, height: 30))
            //btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
            btnItem.translatesAutoresizingMaskIntoConstraints = false
            btnItem.setTitle(item.alias, for: UIControlState.normal)
            btnItem.setTitleColor(UIColor.blue, for: UIControlState.normal)
            //btnItem.backgroundColor = UIColor.lightGray
            // btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
            self.view.addSubview(btnItem)
        }
    }
    
    func clickItem(_ sender: UIButton) {
        let action = sender.titleLabel?.text!
        curLabel.text = "CurrentAction: \(action!)"
        
    }
}

