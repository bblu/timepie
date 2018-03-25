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
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var lastButton: UIButton!
    @IBOutlet weak var spanSlider: UISlider!
    @IBOutlet weak var logLabel: UILabel!
    let inputMode = 1
    var picker = UIPickerView()
    var timer = Timer()
    var tmCounter:Int = 0
    let tdPerfix = ""
    let usrInfo = UserDefaults.standard
    var lastStart:Int = Date().timeIntervalSince1970.exponent
    var weakup = false
    var currCode:Int = 0
    var lastCode:Int = 0
    var lastSpan:Int = 0
    var doneCount:Int = 0
    var notAvailable:Bool = false
    let db = SqliteUtil.timePie
    //---------------------------------------------------------------------
    //*UIPickerViewDataSource
    var tdData:[Int:TodoItem] = [:]
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
        
        if component == 0{
            //print("titleForRow0[select0=\(select0),com=\(component),row=\(row),index=\(row * 100)]")
            return getLabel(index:row * 100)
        }
        let select0 = picker.selectedRow(inComponent: 0)
        let index = select0 * 100 + row
        if row >= comNums[select0]{
            logLabel.text = "unknown index:\(index)"
            return ""
        }
//        print("|---titleForRow1[select0=\(select0),com=\(component),row=\(row),index=\(index)]")
        return getLabel(index:index)
    }
    //public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    // attributed title is favored if both methods are implemented
    //public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let select0 = picker.selectedRow(inComponent: 0)
        let code = select0 * 100 + component * row
        if(component==0){
            picker.reloadComponent(1)
        }
        //print("didSelectRow[select0=\(select0),com=\(component),row=\(row)],index=\(code)")
        tdLabel = getLabel(index: code)
        curLabel.text = tdPerfix + tdLabel + formateTime(interval: 0)
        selectTodo(item:tdData[code]!)
    }

    func getLabel(index:Int)-> String{
        return tdData[index]!.icon + tdData[index]!.name
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
        //db.clearAll();
    }
    
    @IBAction func changeSpan(_ sender: Any) {
        print("changeSpan")
    }
    
    @IBAction func changeLastSpan(_ sender: UIButton) {
        if spanSlider.isHidden{
            let maxValue:Float = Float(lastSpan)
            spanSlider.maximumValue = maxValue * 1.25
            spanSlider.setValue(maxValue, animated: false)
            lastButton.setTitle("💾",for:UIControlState.normal)
        }else{
            lastButton.setTitle("⚙️",for:UIControlState.normal)
        }
        spanSlider.isHidden = !spanSlider.isHidden
    }
    
    @IBAction func lastSpanSlider(_ sender: UISlider) {
        let val = lastStart + Int(sender.value)
        lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.name):\(formateTime(interval: Int(sender.value))) --> \(formateTime(interval:val))"
    }
    
    @IBAction func backupData(_ sender: Any) {
        doneCount = db.backupData()
        usrInfo.set(doneCount, forKey: UserInfoKeys.doneCount)
        logLabel.text = "bkup count = \(doneCount)"
        lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.alias):\(formateTime(interval: tmCounter))"
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
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
                lastStart = usrInfo.integer(forKey: UserInfoKeys.startTime)
                let intNow = Int(Date().timeIntervalSince1970)
                if lastStart == 0 || lastStart > intNow {
                    // for the first time to setup
                    logLabel.text = "init lastStart = Now Interval"
                    lastStart = intNow
                }
                tmCounter = intNow - lastStart
                currCode = usrInfo.integer(forKey: UserInfoKeys.todoCode)
                lastCode = usrInfo.integer(forKey: UserInfoKeys.lastCode)
                lastSpan = usrInfo.integer(forKey: UserInfoKeys.lastSpan)
                doneCount = usrInfo.integer(forKey: UserInfoKeys.doneCount)
                logLabel.text = "lastCode:\(lastCode),lastSpan:\(lastSpan),byNow=\(tmCounter)"
                print("lastCode:\(lastCode),lastSpan:\(lastSpan),byNow=\(tmCounter)")
                //---------database------------
                //let count = db.getItem()
                //print("count = \(count)")
                //---------init  UI------------
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    addPickerView(items: todoConfig.items)
                    //print("curCode=\(currCode),com0=\(currCode/100),com1=\(currCode%100)")
                    //if code==103 will cause a picker init fault for wrong component numberrows
                    picker.selectRow(currCode/100, inComponent: 0, animated: false)
                    picker.selectRow(currCode%100, inComponent: 1, animated: true)
                    tdLabel = getLabel(index: currCode)
                    lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.name):\(formateTime(interval: tmCounter))"
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
            tdData[item.code] = item
            //print("\(item.code) : \(item.alias) and count=\(comNums[item.code/100])")
        }
        //for i in comNums{print("\(i)")}
        //let dsDelegate = TodoPickerDsDelegate(items:items)
        picker.dataSource = self
        picker.delegate = self
        picker.center = self.view.center
        picker.center.y += 100
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
        let now = Int(Date().timeIntervalSince1970)
        let span = now - lastStart
        //only store the item which is longer than a minute
        if span > 90 {
            lastSpan = span
            logLabel.text = db.insert(item: item, start: lastStart, span: lastSpan,spnd:0)
            lastStart = now
            lastCode = currCode
            doneCount += 1
            //print("code:\(tdData[lastCode]!.alias),start\(lastStart),now\(now),span => \(lastSpan)")
            lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.name):\(formateTime(interval: lastSpan))"
            currCode = item.code
            usrInfo.set(doneCount, forKey: UserInfoKeys.doneCount)
            usrInfo.set(currCode, forKey: UserInfoKeys.todoCode)
            usrInfo.set(lastStart, forKey: UserInfoKeys.startTime)
            usrInfo.set(lastCode, forKey: UserInfoKeys.lastCode)
            usrInfo.set(lastSpan, forKey: UserInfoKeys.lastSpan)
        }else{
            notAvailable = true
        }
        tmCounter = 0
    }
    
    @objc func UpdateTimer(){
        if notAvailable{
            notAvailable = false
        }
        tmCounter += 1
        curLabel.text = tdPerfix + tdLabel + " for " + formateTime(interval:tmCounter)
    }
    func formateTime(interval:Int)->String{
        let ma = interval / 60
        if ma < 60{
            return String(format: "%2d:%02d", ma, interval % 60)
        }
        let ha = ma / 60
        let hh = ha % 24
        let mm = ma % 60
        let ss = interval % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }
    
}

