//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    //---------------------------------------------------------------------
    @IBOutlet weak var curLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    let inputMode = 1
    var picker = UIPickerView()
    var timer = Timer()
    var tmCounter:UInt64 = 0
    let tdPerfix = ""
    let usrInfo = UserDefaults.standard
    var lastStart = DispatchTime.now()
    var weakup = false
    var curCode:Int = 0
    //---------------------------------------------------------------------
    //*UIPickerViewDataSource
    var data:[Int:TodoItem] = [:]
    var comNums = [Int]()
    var tdLabel = ""
    public func numberOfComponents(in pickerView: UIPickerView) -> Int{
        //print("returns the number of 'columns[2]' to display")
        return 2
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        //print("returns the number of rows in each component[\(component)]")
        if component == 0 {
            return comNums.count
        }
        let select0 = picker.selectedRow(inComponent: 0)
        print("returns the comNums[\(select0)]=\(comNums[select0]) of rows in component[\(component)]")
        return comNums[select0]
    }
    // UIPickerViewDelegate
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        //print("returns width of row for each component")
        return 150
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
            //print("titleForRow0[select0=\(select0),com=\(component),row=\(row),index=\(row * 100)]")
            return getLabel(index:row * 100)
        }
        var index = select0 * 100 + row
        if index == 105{
            index = 104
            print(" ---***--- error code 105")
        }
        print("|---titleForRow1[select0=\(select0),com=\(component),row=\(row),index=\(index)]")
        return getLabel(index:index)
    }
    //public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    // attributed title is favored if both methods are implemented
    //public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let select0 = picker.selectedRow(inComponent: 0)
        var code = select0 * 100 + component * row
        if(component==0){
            picker.reloadComponent(1)
            picker.selectRow(1, inComponent: 1, animated: true)
            code += 1
            print("Code+1=\(code)")
        }
        print("didSelectRow[select0=\(select0),com=\(component),row=\(row)],index=\(code)")
        tdLabel = getLabel(index: code)
        curLabel.text = tdPerfix + tdLabel
        selectTodo(item:data[code]!)
    }
    
    func getLabel(index:Int)-> String{
        return data[index]!.icon + data[index]!.name
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initInputCtrl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func add2Actions(_ sender: UIButton) {
    }
    
    @IBAction func changeSpan(_ sender: Any) {
    }
    func initInputCtrl(){
        if let path = Bundle.main.path(forResource: "actions", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let todoConfig = try decoder.decode(TodoConfig.self, from: data)
                print(todoConfig.user)
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer),
                                             userInfo: nil, repeats: true)
                //timer.invalidate()
                let tmStart = usrInfo.integer(forKey: UserInfoKeys.startTime)
                let end = DispatchTime.now()
                let span = end.uptimeNanoseconds - UInt64(tmStart)
                let timeInterval = Double(span) / 1_000_000_000
                tmCounter = UInt64(timeInterval)

                curCode = usrInfo.integer(forKey: UserInfoKeys.todoCode)
                print("startTime:\(tmStart),timeInterval=\(timeInterval),code=\(curCode)")
                
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    addPickerView(items: todoConfig.items)
                    print("curCode=\(curCode),com0=\(curCode/100),com1=\(curCode%100)")
                    //if code==103 will cause a picker init fault for wrong component numberrows
                    picker.selectRow(0, inComponent: 0, animated: false)
                    picker.selectRow(curCode/100, inComponent: 0, animated: false)
                    //picker.selectRow(curCode%100, inComponent: 1, animated: true)
                    
                    tdLabel = getLabel(index: curCode)
                    startLabel.text = "\(curCode),span\(timeInterval)"
                }
                weakup = true
                
            } catch {
                print("error:\(error)")                // handle error
            }
        }
    }
    func addPickerView(items:[TodoItem]){
        for item in items{
            if item.code % 100 == 0{
                //print("init comNumbers for \(item.code)")
                comNums.append(1)
            }else{
                comNums[item.code/100] += 1
            }
            data[item.code] = item
            //print("\(item.code) : \(item.alias) and count=\(comNums[item.code/100])")
        }
        //let dsDelegate = TodoPickerDsDelegate(items:items)
        picker.dataSource = self
        picker.delegate = self
        picker.center = self.view.center
        self.view.addSubview(picker)
        //picker.selectRow(1, inComponent: 1, animated: true)
    }
    func addButtons(items:[TodoItem]){
        for item in items{
            let pos = item.code
            //pos: 0， 1,  2,  3,  4
            //   100,101,102,103,104
            let px = (pos % 100) * 80
            let py = 400 + (pos / 100) * 50
            let btnItem = UIButton(frame: CGRect(x:px, y: py, width: 80, height: 30))
            //btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
            btnItem.translatesAutoresizingMaskIntoConstraints = false
            btnItem.setTitle(item.icon+item.alias, for: UIControlState.normal)
            btnItem.setTitleColor(UIColor.blue, for: UIControlState.normal)
            //btnItem.backgroundColor = UIColor.lightGray
            // btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
            self.view.addSubview(btnItem)
        }
    }
    
    func clickItem(_ sender: UIButton) {
        let action = sender.titleLabel?.text!
        curLabel.text = "current is: \(action!)"
        
    }
    func selectTodo(item:TodoItem){
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - lastStart.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
        print("code:\(item.code),span => \(timeInterval)")
        curCode = item.code
        usrInfo.set(curCode, forKey: UserInfoKeys.todoCode)
        usrInfo.set(end.uptimeNanoseconds, forKey: UserInfoKeys.startTime)
        startLabel.text = "\(item.code),span:\(timeInterval)"
        lastStart = end
        tmCounter = 0
    }
    
    @objc func UpdateTimer(){
        tmCounter += 1
        if tmCounter == 30 {
            //picker.selectRow(curCode%100, inComponent: 1, animated: true)
            weakup = false
        }
        let hours = tmCounter / 3600
        let minutes = (tmCounter - hours*3600)/60
        if tmCounter >= 3600{
            let lblTime = String(format: "%02d:%02d", hours, minutes)
            curLabel.text = tdPerfix + tdLabel + " for " + lblTime
        }else{
            let seconds = tmCounter % 60
            let lblTime = String(format: "%2d:%02d", minutes, seconds)
            curLabel.text = tdPerfix + tdLabel + " for " + lblTime
        }
    }
}

