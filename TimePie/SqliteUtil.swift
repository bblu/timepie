//
//  SqliteUtil.swift
//  TimePie
//
//  Created by lu wenbo on 17/03/2018.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import Foundation
import SQLite3

class SqliteUtil{
    private var db: OpaquePointer?
    static let timePie = SqliteUtil()
    
    private init(){
        //the database file
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("timepie.sqlite")
        
        //opening the database
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        //creating table
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Done (id INTEGER PRIMARY KEY AUTOINCREMENT,code INTEGER, name TEXT,start INTEGER,stop INTEGER, span INTEGER,spnd decimal(8,2),desc TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }else{
            print("crate table Done")
        }
    }
    func clearAll(){
        //DROP TABLE IF EXIST
        //DELETE FROM Done
        if sqlite3_exec(db, "DROP TABLE Done", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error delete Done Items: \(errmsg)")
        }else{
            print("Delete Done items")
        }
    }
    
    func insert(item:TodoItem, start:Int, span:Int,spnd:Float) -> String{
        var stmt: OpaquePointer?
        let queryString = "INSERT INTO Done (code,name,start,stop,span,spnd,desc) VALUES (\(item.code),'\(item.name)',\(start),strftime('%s','now'),\(span),\(spnd),'desc')"
        //print(queryString)
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "error preparing insert: \(errmsg)"
        }
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "failure inserting todo: \(errmsg)"
        }
        return "|-into-[\(item.name)]:\(Int(Float(span)*0.01666667))mins saved successfully"
    }
    func getItem()->[DoneItem]{
        //this is our select query
        //
        let queryString = "SELECT id,code,name,start,stop,span,spnd,desc FROM Done"
        //statement pointer
        var stmt:OpaquePointer?
        var doneList = [DoneItem]()
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return doneList
        }
        var a = 0
        
        //traversing through all the records
        //code, name, start,end,span
        //print("sqlite3_step(stmt)=\(sqlite3_step(stmt))")
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = Int(sqlite3_column_int(stmt, 0))
            let code = Int(sqlite3_column_int(stmt, 1))
            let name = String(cString: sqlite3_column_text(stmt, 2))
            let start = Int(sqlite3_column_int(stmt, 3))
            let stop = Int(sqlite3_column_int(stmt, 4))
            let span = Int(sqlite3_column_int(stmt, 5))
            let spnd = Double(sqlite3_column_double(stmt, 6))
            let desc = String(cString: sqlite3_column_text(stmt, 2))
            //print("[\(id)]:c:\(code),n:\(name),s:\(start),e:\(stop),span:\(span)")
            let d = DoneItem(id:id, code:code,name:name, star:start, stop:stop,span:span,spnd:Float(spnd), alia:"alia", desc: desc)
            
            print("[\(d.id)]:c:\(d.code),n:\(d.name),s:\(d.star),e:\(d.stop),span:\(d.span)")
            doneList.append(d)
            a += 1
        }
        return doneList
    }
    func backupData() ->Int {
        // server endpoint
        let endpoint = "http://127.0.0.1:8008/timepie/done"
        
        guard let endpointUrl = URL(string: endpoint) else {
            return -1
        }
        var count = 0
        //Make JSON to send to send to server
        let encoder = JSONEncoder()
        //let todoConfig = try decoder.decode(TodoConfig.self, from: data)
        do{
            let list = getItem()
            count = list.count
            let json = try encoder.encode(list)
            print("donejs=\(json)")
            var request = URLRequest(url: endpointUrl)
            request.httpMethod = "POST"
            request.httpBody = json
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request)
            task.resume()
        }catch {
            print("error:\(error)")                // handle error
            return count
        }
        return count
    }


}
