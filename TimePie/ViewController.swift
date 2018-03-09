//
//  ViewController.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var curLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initButtons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initButtons(){
        if let path = Bundle.main.path(forResource: "actions", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let todoConfig = try decoder.decode(TodoConfig.self, from: data)
                print(todoConfig.user)
                for item in todoConfig.items{
                    addButton(pos: item.code, label:item.alias)
                }
            } catch {
                print("error:\(error)")                // handle error
            }
        }
    }
    
    func addButton(pos:Int,label:String){
        //pos: 10,11,12,13,14
        //     20,21,22,23,24
        let px = (pos % 10) * 80
        let py = 300 + (pos / 10) * 50
        let btnItem = UIButton(frame: CGRect(x:px, y: py, width: 80, height: 30))
        btnItem.addTarget(self, action: Selector("clickItem"), for: UIControlEvents.touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        btnItem.setTitle(label, for: UIControlState.normal)
        btnItem.setTitleColor(UIColor.blue, for: UIControlState.normal)
        btnItem.backgroundColor = UIColor.lightGray
        self.view.addSubview(btnItem)
    }
    
    func clickItem(_ sender: UIButton) {
        let action = sender.titleLabel?.text!
        curLabel.text = "CurrentAction: \(action!)"
        
    }
}

