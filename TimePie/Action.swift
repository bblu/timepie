//
//  Action.swift
//  TimePie
//
//  Created by lu wenbo on 08/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import Foundation

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

struct Action {
    var code:Int        // 3digits support for two steps of actions
    var name:String
    var alias:String
    var desc:String
    var span0:Int       // plan time,todo and action can use one attr
    var span1:Int       // real time for this action
    var value0:Int      // begin
    var value1:Int      // end
}
