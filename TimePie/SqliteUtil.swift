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
        //if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Todo (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, powerrank INTEGER)", nil, nil, nil) != SQLITE_OK {
        //    let errmsg = String(cString: sqlite3_errmsg(db)!)
        //    print("error creating table: \(errmsg)")
        //}
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Done (id INTEGER PRIMARY KEY AUTOINCREMENT,code INTEGER, name TEXT,start INTEGER,end INTEGER, span INTEGER)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }else{
            print("crate table Done")
        }
    }
    
    func insert(item:TodoItem, start:Int, span:Int){
        var stmt: OpaquePointer?
        
        let queryString = "INSERT INTO Done (code, name, start,end,span) VALUES (?,?,?,strftime('%s','now'),?)"
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        if sqlite3_bind_int(stmt, 1, Int32(item.code)) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_bind_text(stmt, 2, item.name, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        if sqlite3_bind_int(stmt, 3, Int32(start)) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_bind_int(stmt, 4, Int32(span)) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting hero: \(errmsg)")
            return
        }
        print("itme saved successfully")
    }
    func getItem()->Int{
        //this is our select query
        let queryString = "SELECT * FROM Done"
        
        //statement pointer
        var stmt:OpaquePointer?
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return 0
        }
        var a = 0
        //traversing through all the records
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let code = sqlite3_column_int(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let start = sqlite3_column_int(stmt, 2)
            a += 1
        }
        return a
    }
    


}
