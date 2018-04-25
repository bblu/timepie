//
//  DoneTodo.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import Foundation

struct UserInfoKeys{
    static let todoCode = "code"
    static let startTime = "start"
    static let lastCode = "last"
    static let lastSpan = "lastSpan"
    static let storCode = "stor"
    static let storSpan = "storSpan"
    static let storSpnd = "storSpnd"
    static let storDesc = "storDesc"
    static let doneCount = "count"
    static let pickCache = "pickCache"
}

struct TodoConfig:Decodable{
    let user:String
    let date:String
    let items:[TodoItem]
}

struct TodoItem: Decodable{
    let name:String
    let alias:String
    let icon:String
    let code:Int
    var span:Int
}

struct PickItem{
    let name:String
    let code:Int
}

struct DoneList: Encodable{
    let items:[DoneItem]
}

struct DoneItem: Encodable{
    let id:Int
    let code:Int      // 3digits support for two steps of actions
    let name:String
    let star:Int      // begin
    let stop:Int      // end
    let span:Int      // real time for this action
    let spnd:Float
    let alia:String
    let desc:String
    let user:String = "bblu"
}
