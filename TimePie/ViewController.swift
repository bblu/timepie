//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Update to swift 4.3 by lu wenbo on 21/10/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

import AudioToolbox

extension Date {
    // returns an integer from 1 - 7, with 1 being monday and 7 being Sunday
    var dayOfWeek: Int {
        // returns an integer from 1 - 7, with 1 being Sunday and 7 being Saturday
        let dow = Calendar.current.dateComponents([.weekday], from: self).weekday!
        //print("dow=\(dow) dayofweek=\(dow-1)")
        return dow==1 ? 7 : dow - 1
    }
    func dayOfWeek(start:Date) -> Int {
        let dow = Calendar.current.dateComponents([.weekday], from: start).weekday!
        return dow==1 ? 7 : dow - 1
    }
    var dayOfMonth:Int{
        return Calendar.current.component(.day, from: self)
    }
    var daysOfLastMonth:Int{
        let diffCom = Calendar.current.dateComponents([.day], from: self.lastMonth, to: self)
        return diffCom.day!
    }
    var thisDay: Date {
        let base = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: self))!
        //let today = Calendar.current.date(byAdding: .hour, value: 8, to: base)!
        return base
    }
    
    var thisWeek: Date {
        let base = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        //the start of week is sunday make it to monday
        let week = Calendar.current.date(byAdding: .day, value: 1, to: base)!
        if week < self { return week}
        return Calendar.current.date(byAdding: .day, value: -6, to: base)!
    }
    var thisMonth: Date {
        let base = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        //let month = Calendar.current.date(byAdding: .hour, value: 8, to: base)!
        return base
    }
    var lastMonth: Date {
        let base = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        return Calendar.current.date(byAdding: .month, value: -1, to: base)!
    }
}

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    //---------------------------------------------------------------------
    @IBOutlet weak var curLabel: UILabel!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var lastButton: UIButton!
    @IBOutlet weak var spanSlider: UISlider!
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var todoPickerView: UIPickerView!
    @IBOutlet weak var doneTableView: UITableView!
    @IBOutlet weak var statisticsLabel: UILabel!
    @IBOutlet weak var spendText: UITextField!
    @IBOutlet weak var descText: UITextField!
    
    static let localOffset = 28800
    let dateFmt = DateFormatter()
    let minTimespan = 60
    //同步到苹果日历的最短时间阈值=25mins
    let minCalespan = 1500
    let stdUserDefaults = UserDefaults.standard
    
    let db = SqliteUtil.timePie
    let ap = CalendarUtil()
    
    var doneAmount:Int = 0
    var timer = Timer()
    var tmCounter:Int = 0
    let inputMode = 1

    var lastStar:Int = 0
    var currCode:Int = 0
    var lastCode:Int = 0
    var lastSpan:Int = 0
    var storCode:Int = 0
    var storSpan:Int = 0
    var storSpnd:Float = 0.0
    var storDesc:String = ""
    let langIsEn = true
    
    //-----------------------
    //*UIPickerViewDataSource
    var todoItems:[Int:TodoItem] = [:]
    var pickItems:[Int:String]=[:]
    var comNums = [Int]()
    var pickCache = [Int]()
    var tdLabel = ""
    public func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 2
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        if component == 0 {
            return comNums.count
        }
        let select0 = todoPickerView.selectedRow(inComponent: 0)
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
            return pickItems[row * 100]!
        }
        let select0 = todoPickerView.selectedRow(inComponent: 0)
        let index = select0 * 100 + row
        if row >= comNums[select0]{
            uiLogError(msg: "unknown index:\(index) for pickerView")
            return ""
        }
        return pickItems[index]
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let select0 = todoPickerView.selectedRow(inComponent: 0)
        var nextCode:Int = 0
        if(component==0){
            pickerView.reloadComponent(1)
            pickerView.selectRow(pickCache[row], inComponent: 1, animated: false)
            if(spanSlider.isHidden){
                nextCode = select0 * 100 + pickCache[row]
            }else{
                setLastCode(code: select0 * 100 + pickCache[row])
            }
        }else{
            if(spanSlider.isHidden){
                pickCache[select0] = row
                stdUserDefaults.set(pickCache, forKey: UserInfoKeys.pickCache)
                nextCode = select0 * 100 + row
            }else{
                setLastCode(code:select0 * 100 + row)
            }
        }
        if(spanSlider.isHidden){
            tdLabel = pickItems[nextCode]!
            curLabel.text = "\(tdLabel) for 0:00"
            if nextCode != currCode{
                selectNext(nextCode:nextCode)
            }
        }
    }
    
    @objc func flushUI(_ notification:Notification) {
        let pc = stdUserDefaults.array(forKey: UserInfoKeys.pickCache)
        if pc != nil && pickCache.count<1{
            for i in pc!{
                pickCache.append(i as! Int)
                if pickCache.count > 10{
                    break
                }
            }
        }
        //print("pickCache.count = \(pickCache.count)")
        storCode = stdUserDefaults.integer(forKey: UserInfoKeys.storCode)
        storSpan = stdUserDefaults.integer(forKey: UserInfoKeys.storSpan)
        storSpnd = stdUserDefaults.float(forKey: UserInfoKeys.storSpnd)
        let desc = stdUserDefaults.string(forKey: UserInfoKeys.storDesc)
        storDesc = desc == nil ? "" : desc!
        lastStar = stdUserDefaults.integer(forKey: UserInfoKeys.startTime)
        lastCode = storCode
        lastSpan = storSpan

        let intNow = Int(Date().timeIntervalSince1970)
        if lastStar == 0 || lastStar > intNow {
            lastStar = intNow
            uiLogInfo(msg: "|-init lastStart = Now")
        }
        tmCounter = intNow - lastStar
        currCode = stdUserDefaults.integer(forKey: UserInfoKeys.todoCode)
        tdLabel = pickItems[currCode]!
        //print("lastCode or storCode = \(lastCode)")
        uiLogInfo(msg: "Done={\(todoItems[lastCode]!.name):\(Int((lastSpan+30)/60))m} and Doing={\(todoItems[currCode]!.name):\(Int((tmCounter+30)/60))m}")
        setPickerViewTo(code: currCode)
        //print("|-[user]-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}")
        flushLastLabel()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(flushUI(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        if let path = Bundle.main.path(forResource: "actions", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let todoConfig = try decoder.decode(TodoConfig.self, from: data)
                spendText.placeholder = "¥"
                //print(todoConfig.user)
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer),
                                             userInfo: nil, repeats: true)
                //timer.invalidate()
                //---------init  UI------------
                if inputMode == 0 {
                    addButtons(items: todoConfig.items)
                }else{
                    doneTableView.isHidden = true
                    descText.isHidden = true
                    addPickerView(items: todoConfig.items)
                    let amouunt = db.getItemCount()
                    if amouunt < 0 {
                        uiLogError(msg: "cannot get done count")
                    }else{
                        setDoneAmount(count: amouunt)
                    }
                    //print("|-[info]-vdid-Done={\(lastCode):\(lastSpan)s} Doing={\(currCode):\(tmCounter)s}")
                }
            } catch {
                print("error:\(error)")                // handle error
                uiLogError(msg: error.localizedDescription)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self,
            name:UIApplication.didBecomeActiveNotification,object: nil)
        print("removeObserver")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func add2Actions(_ sender: UIButton) {
        if doneAmount == 0{
            uiLogInfo(msg: "no item to delete")
            return
        }
        let alert = UIAlertController(title: "Alert", message:"Delete All \(doneAmount) Items?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .`cancel`, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .`default`, handler: { _ in
            let msg = self.db.clearAll()
            //self.uiLog(log: self.db.recreateTableDone())
            if msg == "ok" {
                self.uiLogInfo(msg: "delete all Done items");
                self.resetDoneAmount()
            }else{
                self.uiLogError(msg: msg)
            }

        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addDescription(_ sender: UIButton) {
        descText.isHidden = !descText.isHidden
        if descText.isHidden{
            sender.setTitle("➕", for: UIControl.State.normal)
        }else{
            sender.setTitle("➖", for: UIControl.State.normal)
        }
        self.view.endEditing(true)
    }
    @IBAction func staticSpanChanged(_ sender: UISegmentedControl) {
        genStatistics(index: sender.selectedSegmentIndex)
    }
    
    @IBAction func changeLastSpan(_ sender: UIButton) {
        if spanSlider.isHidden{
            //start Edit
            let maxValue:Float = Float(storSpan)
            spanSlider.maximumValue = maxValue * 1.25
            spanSlider.setValue(maxValue, animated: false)
            lastButton.setTitle("💾",for:UIControl.State.normal)
            setPickerViewTo(code:storCode)
        }else{
            //save Edit
            var newSpan = -1
            if abs(storSpan - Int(spanSlider.value)) > minTimespan{
                newSpan = Int(spanSlider.value)
            }else{
                uiLogInfo(msg: "timespan is too short to reset")
            }
            let txtSpnd = spendText.text!
            let newDesc = descText.text!
            let newSpnd = (txtSpnd as NSString).floatValue
            if newSpan > 0 || newSpnd>0 || newDesc != ""{
                let log = db.updateLast(newSpan: newSpan, newDesc: newDesc, newSpnd: newSpnd)
                if "i" == log.prefix(4).suffix(1){
                    if newSpan > 0{
                        updateLastSpanData(newSpan:newSpan)
                        storSpan = newSpan
                    }
                    if newSpnd>0 || newDesc != ""{
                        updateLastSpndDesc(newSpnd: newSpnd, newDesc: newDesc)
                    }
                }else{
                    uiLog(log: log)
                }
                let lastApId = stdUserDefaults.string(forKey: UserInfoKeys.lastApId)
                if lastApId != nil && lastApId != ""{
                    let calName = todoItems[storCode/100*100]!.name
                    let apId = lastApId!
                    let newApId = ap.updateLastCalendar(calendar: calName, apId: apId,code:storCode ,newSpan: lastSpan, newDesc: newDesc, newSpnd: newSpnd)
                    if newApId.prefix(1) != "|"{
                        stdUserDefaults.set(newApId, forKey: UserInfoKeys.lastApId)
                    }else{
                        uiLog(log:newApId)
                    }
                }
                flushLastLabel()
            }
            lastButton.setTitle("⚙️",for:UIControl.State.normal)
            setPickerViewTo(code: currCode)
        }
        statisticsLabel.isHidden = spanSlider.isHidden
        spanSlider.isHidden = !spanSlider.isHidden
        cancelEditButton.isHidden = spanSlider.isHidden
    }
    @IBAction func cancelEditLast(_ sender: UIButton) {
        flushLastLabel()
        lastButton.setTitle("⚙️",for:UIControl.State.normal)
        spanSlider.isHidden = true
        sender.isHidden = true
        statisticsLabel.isHidden = false
    }
    @IBAction func lastSpanSlider(_ sender: UISlider) {
        lastSpan = Int(sender.value)
        dateFmt.dateFormat = "H:mm:ss"
        //+ ViewController.localOffset
        let loc = dateFmt.string(from: Date(timeIntervalSince1970: Double(lastStar + lastSpan )))
        flushLastLabel(extra:"->\(loc)")
    }
    
    @IBAction func backupData(_ sender: Any) {
        //let items = db.getItem()
        //for item in items{
        //    addEventToCalendar(item: todoItems[item.code]!, start:item.star, desc: item.desc, spnd: item.spnd, span: item.span,stop:item.stop)
        //    print("bkup for \(item.code):\(item.name)-\(item.span)")
        //}
        //return
        //todo 异步调用连接超时的问题
        doneAmount = db.backupData()
        if doneAmount < 0 {
            doneAmount *= -1
            uiLogError(msg: "cannot connect to bkup address for \(doneAmount)")
        }else{
            stdUserDefaults.set(doneAmount, forKey: UserInfoKeys.doneCount)
            uiLogInfo(msg: "bkup count = \(doneAmount) span\(lastSpan)|tm\(tmCounter)")
            //lastSpan = tmCounter
            flushLastLabel()
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    func addPickerView(items:[TodoItem]){
        for item in items{
            if item.code % 100 == 0{
                comNums.append(1)
                pickCache.append(0)
            }else{
                comNums[item.code/100] += 1
            }
            //db.alterCodeByName(name: item.name, code:item.code)
            todoItems[item.code] = item
            if langIsEn {
                pickItems[item.code] = item.icon + item.name
            }else{
                pickItems[item.code] = item.icon + item.alias
            }
        }
        //db.alterTableDone()
        todoPickerView.dataSource = self
        todoPickerView.delegate = self
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
            btnItem.setTitle(item.icon+item.alias, for: UIControl.State.normal)
            btnItem.setTitleColor(UIColor.blue, for: UIControl.State.normal)
            //btnItem.backgroundColor = UIColor.lightGray
            // btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
            self.view.addSubview(btnItem)
        }
    }
    
    func clickItem(_ sender: UIButton) {
        let action = sender.titleLabel?.text!
        curLabel.text = "current is: \(action!)"
        
    }
    func selectNext(nextCode:Int){
        let now = Int(Date().timeIntervalSince1970)
        let span = now - lastStar
        //only store the item which is longer than a minute
        lastCode = currCode
        lastSpan = span
        currCode = nextCode
        if span > minTimespan {
            let item = todoItems[lastCode]!
            let txtSpnd = spendText.text!
            let txtDesc = descText.text!
            let fltSpnd = (txtSpnd as NSString).floatValue
            saveLastItem(item: item, spnd: fltSpnd, desc: txtDesc)
            lastStar = now
        }
        //print("|-[info]-stor:\(tdData[storCode]!.name) last=\(tdData[lastCode]!.name)")
        storeUserInfo()
        tmCounter = 0
    }
    
    func genStatistics(index:Int){
        var begin:Date = Date().thisDay
        var days = 1
        var weekdays = 1
        if index > 0{
            let today = Calendar.current.component(.hour, from: Date()) > 18 ? 1 : 0
            if index == 1{
                begin = Date().thisWeek
                days = Date().dayOfWeek - 1 + today
                weekdays = days > 5 ? 5 : days
            } else if index == 2 {
                begin = Date().thisMonth
                days = Date().dayOfMonth - 1 + today
                //from the very beginning of the month count last month data
                if days < 4{
                    begin = Date().lastMonth
                    days = Date().daysOfLastMonth + days
                }
                weekdays = weekdaysByNow(dayofweek: Date().dayOfWeek(start:begin), days: days)
            }
        }
        todoPickerView.isHidden = index > 0
        doneTableView.isHidden = index < 1
        //db.intoMainClassSince(begin:Int(begin.timeIntervalSince1970))
        //db.checkSpanSince(begin: Int(begin.timeIntervalSince1970))
        dateFmt.dateFormat = "MM-dd HH:mm"
        uiLogInfo(msg: "from=\(dateFmt.string(from:begin)), days=\(days), weekdays=\(weekdays)")
        //return
        let sumMain = db.sumMainClassSince(begin:Int(begin.timeIntervalSince1970))
        var statistics = ""
        for (main,sum) in sumMain.enumerated(){
            //print("\(main):\(Double(sum)/3600.0)")
            if  sum > 0 {
                if main == 3{
                    statistics += "\(todoItems[main*100]!.icon)\(shortTime(interval: Double(sum), days:Double(weekdays))) "
                }else{
                    statistics += "\(todoItems[main*100]!.icon)\(shortTime(interval: Double(sum), days:Double(days))) "
                }
            }
        }
        statisticsLabel.text = statistics
    }
    func saveLastItem(item:TodoItem,spnd:Float,desc:String){
        let msg = db.insert(item:item ,start: lastStar, span: lastSpan,spnd:spnd,desc:desc)
        if msg == "ok"{
            increaseDoneAmount()
            
            var title = item.name
            if !langIsEn{
                title = item.alias
            }
            if lastSpan > minCalespan || spnd > 4 || desc != "" {
                let calName = todoItems[item.code/100*100]!.name
                let log = ap.addEventToCalendar(calendar: calName, code: lastCode, title: title, start: lastStar, desc: desc,spnd:spnd, span:lastSpan)
                if "|" == log.prefix(1){
                    uiLog(log: log)
                }else{
                    stdUserDefaults.set(log, forKey: UserInfoKeys.lastApId)
                    uiLogInfo(msg:"[\(item.code):\(item.name)] for \(Int(Float(lastSpan)*0.01666667)+1)mins \(spnd) \(desc) saved")
                }
            }
            spendText.text = ""
            if descText.isHidden{
                descText.text = ""
            }
        }else{
            uiLogError(msg: msg)
        }
    }
    

    func setLastCode(code:Int){
        let msg = db.updateLastCode(newCode: code, name:todoItems[code]!.name)
        if msg == "ok" {
            lastCode = code
            storCode = code
            flushLastLabel()
            uiLogInfo(msg: "set lastCode = \(lastCode), lastName = \(todoItems[code]!.name)")
        }else{
            uiLogError(msg: msg)
        }
    }
    func updateLastSpanData(newSpan:Int){
        lastStar -= storSpan - newSpan
        tmCounter += storSpan - newSpan
        storSpan = newSpan
        lastSpan = newSpan
        stdUserDefaults.set(lastStar, forKey: UserInfoKeys.startTime)
        stdUserDefaults.set(lastSpan, forKey: UserInfoKeys.lastSpan)
        stdUserDefaults.set(lastSpan, forKey: UserInfoKeys.storSpan)
    }
    func updateLastSpndDesc(newSpnd:Float, newDesc:String){
        storSpnd = newSpnd
        storDesc = newDesc
        stdUserDefaults.set(storSpnd, forKey: UserInfoKeys.storSpnd)
        stdUserDefaults.set(storDesc, forKey: UserInfoKeys.storDesc)
        spendText.text = ""
        descText.text = ""
        descText.isHidden = true
    }
    @objc func UpdateTimer(){
        tmCounter += 1
        curLabel.text = tdLabel + " : " + formateTime(interval:tmCounter)
        if tmCounter < 0 {
            let sid = SystemSoundID(kSystemSoundID_Vibrate)
            AudioServicesPlaySystemSound(sid)
            uiLog(log: "play sid")
        }
    }
    
    func resetDoneAmount(){
        setDoneAmount(count: 0)
        uiLog(log: db.insert(item: todoItems[lastCode]!, start: lastStar,
                                  span: lastSpan,spnd:0.0,desc:"auto insert"))
    }
    
    func increaseDoneAmount(){
        storCode = lastCode
        storSpan = lastSpan
        self.stdUserDefaults.set(0, forKey: UserInfoKeys.doneCount)
        stdUserDefaults.set(lastCode, forKey: UserInfoKeys.storCode)
        //print("set storCode = \(lastCode)")
        stdUserDefaults.set(storSpan, forKey: UserInfoKeys.storSpan)
        setDoneAmount(count: doneAmount+1)
    }
    func setDoneAmount(count:Int){
        doneAmount = count
        flushLastLabel()
    }
    func flushLastLabel(extra:String=""){
        if(langIsEn){
            lastLabel.text = "[\(doneAmount)]\(todoItems[storCode]!.name):\(formateTime(interval: lastSpan))"
        }else{
            lastLabel.text = "[\(doneAmount)]\(todoItems[storCode]!.alias):\(formateTime(interval: lastSpan))"
        }
        if extra != ""{
            lastLabel.text =  lastLabel.text! + extra
        }
    }
    func storeUserInfo(){
        stdUserDefaults.set(currCode, forKey: UserInfoKeys.todoCode)
        stdUserDefaults.set(lastCode, forKey: UserInfoKeys.lastCode)
        stdUserDefaults.set(lastStar, forKey: UserInfoKeys.startTime)
        stdUserDefaults.set(lastSpan, forKey: UserInfoKeys.lastSpan)
    }
    func setPickerViewTo(code:Int){
        todoPickerView.selectRow(code/100, inComponent: 0, animated: false)
        todoPickerView.reloadComponent(1)
        todoPickerView.selectRow(code%100, inComponent: 1, animated: false)
    }
    
    func uiLogError(msg:String){
        uiLog(log: "|-[error]-\(msg)")
    }
    func uiLogInfo(msg:String){
        uiLog(log: "|-[info]-\(msg)")
    }
    func uiLog(log:String){
        logLabel.text = log
    }
    func weekdaysByNow(dayofweek:Int, days:Int)->Int{
        var weekdays = 0
        var w = dayofweek
        for _ in (0...days){
            w = w % 7
            if 0 < w && w < 6{
                weekdays += 1
            }
            w += 1
        }
        return weekdays
    }
    func formateTime(interval:Int)->String{
        let ma = (interval) / 60
        if ma < 60{
            return String(format: "%2d:%02d", ma, interval % 60)
        }
        let ha = ma / 60
        //let hh = ha % 24
        let mm = ma % 60
        let ss = interval % 60
        print("formateTime = \(interval):\(ha), \(mm), \(ss)")
        return String(format: "%d:%02d:%02d", ha, mm, ss)
    }
    func shortTime(interval:Double,days:Double)->String{
        if interval > (3600 * days){
            return String(format: "%.1f", interval / (3600 * days))
        }
        return String(format: "%.0f", interval / (60 * days))
    }
    
}

