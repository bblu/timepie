//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    //---------------------------------------------------------------------
    @IBOutlet weak var curLabel: UILabel!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var lastButton: UIButton!
    @IBOutlet weak var spanSlider: UISlider!
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var logLabel: UILabel!
    
    static let localOffset = 28800
    let stdUserDefaults = UserDefaults.standard
    let db = SqliteUtil.timePie
    var doneAmount:Int = 0
    var picker = UIPickerView()
    var timer = Timer()
    var tmCounter:Int = 0
    let inputMode = 1
    let tdPerfix = ""

    var lastStart:Int = 0
    var currCode:Int = 0
    var lastCode:Int = 0
    var lastSpan:Int = 0
    
    //-----------------------
    //*UIPickerViewDataSource
    var tdData:[Int:TodoItem] = [:]
    var comNums = [Int]()
    var comCache = [Int]()
    var tdLabel = ""
    public func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 2
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        if component == 0 {
            return comNums.count
        }
        let select0 = picker.selectedRow(inComponent: 0)
        return comNums[select0]
    }
    // UIPickerViewDelegate
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat{
        return 150
    }
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat{
        return 35
    }
    
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        if component == 0{
            
            return getLabel(index:row * 100)
        }
        let select0 = picker.selectedRow(inComponent: 0)
        let index = select0 * 100 + row
        if row >= comNums[select0]{
            uiLog(log: "|-[error]-index:\(index) for pickerView")
            return ""
        }
        //print("|-[info]=[select0=\(select0),com=\(component),row=\(row)")
        return getLabel(index:index)
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let select0 = picker.selectedRow(inComponent: 0)
        
        if(component==0){
            picker.reloadComponent(1)
            pickerView.selectRow(comCache[row], inComponent: 1, animated: false)
        }else{
            comCache[select0] = row
        }
        let code = select0 * 100 + component * row
        
        tdLabel = getLabel(index: code)
        curLabel.text = "\(tdPerfix)\(tdLabel) for 0:00"
        //print("|-[info]=[select0=\(select0),com=\(component),row=\(row)],label=\(tdLabel)")
        selectTodo(item:tdData[code]!)
    }

    func getLabel(index:Int)-> String{
        return tdData[index]!.icon + tdData[index]!.name
    }
    
    @objc func flushUI(_ notification:Notification) {
        lastCode = stdUserDefaults.integer(forKey: UserInfoKeys.lastCode)
        lastStart = stdUserDefaults.integer(forKey: UserInfoKeys.startTime)
        lastSpan = stdUserDefaults.integer(forKey: UserInfoKeys.lastSpan)
        let intNow = Int(Date().timeIntervalSince1970)
        if lastStart == 0 || lastStart > intNow {
            // for the first time to setup
            uiLog(log: "init lastStart = Now Interval")
            lastStart = intNow
        }
        tmCounter = intNow - lastStart
        currCode = stdUserDefaults.integer(forKey: UserInfoKeys.todoCode)
        tdLabel = getLabel(index: currCode)
        uiLog(log: "|-[info]-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}")
        picker.selectRow(currCode/100, inComponent: 0, animated: false)
        picker.reloadComponent(1)
        picker.selectRow(currCode%100, inComponent: 1, animated: false)
        //print("|-[user]-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}")
        flushLastLabel()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(flushUI(_:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
        if let path = Bundle.main.path(forResource: "actions", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let todoConfig = try decoder.decode(TodoConfig.self, from: data)
                print(todoConfig.user)
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer),
                                             userInfo: nil, repeats: true)
                //timer.invalidate()
                //---------init  UI------------
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    addPickerView(items: todoConfig.items)
                    let amouunt = db.getItemCount()
                    if amouunt < 0 {
                        uiLog(log: "|-[error]-cannot get done count")
                    }else{
                        setDoneAmount(count: amouunt)
                    }
                    //print("|-[info]-vdid-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}")
                }
            } catch {
                print("error:\(error)")                // handle error
                uiLog(log: "|-[error]-\(error)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self,
            name:NSNotification.Name.UIApplicationDidBecomeActive,object: nil)
        print("removeObserver")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func add2Actions(_ sender: UIButton) {
        if doneAmount == 0{
            uiLog(log: "|-[info]-no item to delete")
            return
        }
        let alert = UIAlertController(title: "Alert", message:"Delete All \(doneAmount) Items?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .`cancel`, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { _ in
            self.uiLog(log: self.db.clearAll());
            //self.uiLog(log: self.db.recreateTableDone())
            self.resetDoneAmount()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeSpan(_ sender: Any) {
        print("changeSpan")
    }
    
    @IBAction func changeLastSpan(_ sender: UIButton) {
        if spanSlider.isHidden{
            //start Edit
            let maxValue:Float = Float(lastSpan)/60
            spanSlider.maximumValue = maxValue * 1.25
            spanSlider.setValue(maxValue, animated: false)
            lastButton.setTitle("💾",for:UIControlState.normal)
        }else{
            //save Edit
            let span = Int(spanSlider.value*60)
            if abs(lastSpan - span) < 180{
                flushLastLabel()
                uiLog(log: "|-[info]-time span is too short to store...")
            }else{
                uiLog(log: db.updateLastEnd(lastStart: lastStart, newSpan: span))
            }
            lastButton.setTitle("⚙️",for:UIControlState.normal)
        }
        spanSlider.isHidden = !spanSlider.isHidden
        cancelEditButton.isHidden = spanSlider.isHidden
    }
    @IBAction func cancelEditLast(_ sender: UIButton) {
        flushLastLabel()
        lastButton.setTitle("⚙️",for:UIControlState.normal)
        spanSlider.isHidden = true
        sender.isHidden = true
    }
    @IBAction func lastSpanSlider(_ sender: UISlider) {
        let val = Int(sender.value*60)
        let loc = lastStart + val + ViewController.localOffset
        lastLabel.text = "[\(doneAmount)]\(tdData[lastCode]!.name):\(formateTime(interval: val)) -> \(formateTime(interval:loc))"
    }
    
    @IBAction func backupData(_ sender: Any) {
        doneAmount = db.backupData()
        if doneAmount < 0{
            uiLog(log: "|-[error]-cannot connect to bkup address")
        }else{
            stdUserDefaults.set(doneAmount, forKey: UserInfoKeys.doneCount)
            uiLog(log: "|-[info]-bkup count = \(doneAmount) span\(lastSpan)|tm\(tmCounter)")
            //lastSpan = tmCounter
            flushLastLabel()
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    func addPickerView(items:[TodoItem]){
        for item in items{
            if item.code % 100 == 0{
                //print("init comNumbers for \(item.code)")
                comNums.append(1)
                comCache.append(0)
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
        lastCode = currCode
        currCode = item.code
        if span > 60 {
            uiLog(log: db.insert(item: tdData[lastCode]!, start: lastStart,
                                 span: span,spnd:0.0,desc:""))
            increaseDoneCount()
        }
        lastStart = now
        lastSpan = span
        storeUserInfo()
        tmCounter = 0
    }
    
    @objc func UpdateTimer(){
        tmCounter += 1
        curLabel.text = tdPerfix + tdLabel + " for " + formateTime(interval:tmCounter)
        if tmCounter < 0 {
            let sid = SystemSoundID(kSystemSoundID_Vibrate)
            AudioServicesPlaySystemSound(sid)
            uiLog(log: "play sid")
        }
    }
    
    func resetDoneAmount(){
        setDoneAmount(count: 0)
        uiLog(log: db.insert(item: tdData[lastCode]!, start: lastStart,
                                  span: lastSpan,spnd:0.0,desc:"auto insert"))
    }
    
    func increaseDoneCount(){
        setDoneAmount(count: doneAmount+1)
    }
    func setDoneAmount(count:Int){
        doneAmount = count
        self.stdUserDefaults.set(0, forKey: UserInfoKeys.doneCount)
        flushLastLabel()
    }
    func flushLastLabel(){
        lastLabel.text = "[\(doneAmount)]\(tdData[lastCode]!.name):\(formateTime(interval: lastSpan))"
    }
    func storeUserInfo(){
        //usrInfo.set(doneCount, forKey: UserInfoKeys.doneCount)
        stdUserDefaults.set(currCode, forKey: UserInfoKeys.todoCode)
        stdUserDefaults.set(lastStart, forKey: UserInfoKeys.startTime)
        stdUserDefaults.set(lastCode, forKey: UserInfoKeys.lastCode)
        stdUserDefaults.set(lastSpan, forKey: UserInfoKeys.lastSpan)
    }
    func uiLog(log:String){
        logLabel.text = log
    }
    func formateTime(interval:Int)->String{
        let ma = (interval) / 60
        if ma < 60{
            return String(format: "%2d:%02d", ma, interval % 60)
        }
        let ha = ma / 60
        let hh = ha % 24
        let mm = ma % 60
        //let ss = interval % 60
        return String(format: "%02d:%02d", hh, mm)
    }
    
}

