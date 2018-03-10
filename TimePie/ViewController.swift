//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var curText: UITextField!
    @IBOutlet weak var curLabel: UILabel!
    
    
    let inputMode = 1
    var picker = UIPickerView()
    
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
                    curText.inputView = picker
                    curText.placeholder = "select a action"
                }
            } catch {
                print("error:\(error)")                // handle error
            }
        }
    }
    func addPickerView(items:[TodoItem]){
        let dsDelegate = TodoPickerDsDelegate(items:items)
        picker.dataSource = dsDelegate
        picker.delegate = dsDelegate
        picker.center = self.view.center
        self.view.addSubview(picker)
        picker.reloadAllComponents()
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

