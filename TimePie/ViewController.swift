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
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var logLabel: UILabel!
    
    static let localOffset = 28800
    var picker = UIPickerView()
    var timer = Timer()
    var tmCounter:Int = 0
    let inputMode = 1
    let tdPerfix = ""
    let usrInfo = UserDefaults.standard
    var lastStart:Int = Date().timeIntervalSince1970.exponent
    var currCode:Int = 0
    var lastCode:Int = 0
    var lastSpan:Int = 0
    var doneCount:Int = 0
 
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
            uiLog(log: "|-[error]-index:\(index) for pickerView")
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
        
        if(component==0){
            picker.reloadComponent(1)
            pickerView.selectRow(0, inComponent: 1, animated: false)
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
    @objc func applicationDidBecomeActive(_ notification:Notification) {
        getUserInfo()
    }
    func getUserInfo(){
        //doneCount = usrInfo.integer(forKey: UserInfoKeys.doneCount)
        //print("getDoneCount = \(doneCount)")
        lastCode = usrInfo.integer(forKey: UserInfoKeys.lastCode)
        lastStart = usrInfo.integer(forKey: UserInfoKeys.startTime)
        lastSpan = usrInfo.integer(forKey: UserInfoKeys.lastSpan)
        let intNow = Int(Date().timeIntervalSince1970)
        if lastStart == 0 || lastStart > intNow {
            // for the first time to setup
            uiLog(log: "init lastStart = Now Interval")
            lastStart = intNow
        }
        tmCounter = intNow - lastStart
        currCode = usrInfo.integer(forKey: UserInfoKeys.todoCode)
        picker.selectRow(currCode/100, inComponent: 0, animated: false)
        picker.reloadComponent(1)
        picker.selectRow(currCode%100, inComponent: 1, animated: false)
        tdLabel = getLabel(index: currCode)
        flushLastLabel()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
                //NSNotificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)),
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
                
                uiLog(log: "|-[info]-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}|\(logLabel.text!)")
                //print("lastCode:\(lastCode),lastSpan:\(lastSpan),byNow=\(tmCounter),curSpan=\(tmCounter)")
                //---------database------------
                //let count = db.getItem()
                //print("count = \(count)")
                //---------init  UI------------
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    addPickerView(items: todoConfig.items)
                }
                let c = db.getItemCount()
                if c < 0{
                    uiLog(log: "|-[error]-cannot get done count")
                }else{
                    //print("setDoneCount = \(c)")
                    setDoneCount(count: c)
                }
            } catch {
                print("error:\(error)")                // handle error
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
        if doneCount == 0{
            uiLog(log: "|-[info]-no item to delete")
            return
        }
        let alert = UIAlertController(title: "Alert", message:"Delete All \(doneCount) Items?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .`cancel`, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { _ in
            self.uiLog(log: self.db.clearAll());
            self.resetDoneCount()
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
        lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.name):\(formateTime(interval: val)) -> \(formateTime(interval:loc))"
    }
    
    @IBAction func backupData(_ sender: Any) {
        doneCount = db.backupData()
        if doneCount < 0{
            uiLog(log: "|-[error]-cannot connect to bkup address")
        }else{
            usrInfo.set(doneCount, forKey: UserInfoKeys.doneCount)
            uiLog(log: "|-[info]-bkup count = \(doneCount) span\(lastSpan)|tm\(tmCounter)")
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
        if span > 60 {
            uiLog(log: db.insert(item: tdData[currCode]!, start: lastStart,
                                      span: span,spnd:0.0,desc:""))
        }else{
            //print("selectTodo lastCode=\(lastCode) span=\(span)")
        }
        lastCode = currCode
        lastStart = now
        lastSpan = span
        currCode = item.code
        storeUserInfo()
        if span > 60{
            increaseDoneCount()
        }
        tmCounter = 0
    }
    
    @objc func UpdateTimer(){
        tmCounter += 1
        curLabel.text = tdPerfix + tdLabel + " for " + formateTime(interval:tmCounter)
    }
    func resetDoneCount(){
        setDoneCount(count: 0)
        uiLog(log: db.insert(item: tdData[lastCode]!, start: lastStart,
                                  span: lastSpan,spnd:0.0,desc:"auto insert"))
    }
    func increaseDoneCount(){
        setDoneCount(count: doneCount+1)
    }
    func setDoneCount(count:Int){
        doneCount = count
        print("setDoneCount lastCode=\(lastCode)")
        self.usrInfo.set(0, forKey: UserInfoKeys.doneCount)
        flushLastLabel()
    }
    func flushLastLabel(){
        lastLabel.text = "[\(doneCount)]\(tdData[lastCode]!.name):\(formateTime(interval: lastSpan))"
    }
    func storeUserInfo(){
        //usrInfo.set(doneCount, forKey: UserInfoKeys.doneCount)
        usrInfo.set(currCode, forKey: UserInfoKeys.todoCode)
        usrInfo.set(lastStart, forKey: UserInfoKeys.startTime)
        usrInfo.set(lastCode, forKey: UserInfoKeys.lastCode)
        usrInfo.set(lastSpan, forKey: UserInfoKeys.lastSpan)
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

