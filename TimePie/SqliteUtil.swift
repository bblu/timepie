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
    let dateFmt = DateFormatter()
    func formateTime(i:Int)->String{
        dateFmt.dateFormat = "dd HH:mm"
        return dateFmt.string(from: Date(timeIntervalSince1970: Double(i)))
    }
    private var db: OpaquePointer?
    private var addr = "http://127.0.0.1:8008"
    static let timePie = SqliteUtil()

    private init(){
        //the database file
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("timepie.sqlite")
        
        //opening the database
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        _ = createTableDone()
    }
    
    func createTableDone()->String{
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Done (id INTEGER PRIMARY KEY AUTOINCREMENT,code INTEGER, name TEXT,star INTEGER,stop INTEGER, span INTEGER,spnd decimal(8,2),desc TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
            return errmsg
        }
        return  "create table Done"
    }
    
    func alterCodeByName(name:String, code:Int){
        if sqlite3_exec(db, "UPDATE Done SET code = \(code) WHERE name='\(name)'", nil, nil, nil) == SQLITE_OK {
            print("set \(name) code=\(code)")
            
        }else{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error update table: \(errmsg)")
        }
    }
    
    func alterTableDone()->String {
        //sqlite3_exec(db, "CREATE INDEX index_main ON Done (main);", nil, nil, nil)
        //sqlite3_exec(db, "CREATE INDEX index_code ON Done (code);", nil, nil, nil)
        //if sqlite3_exec(db, "UPDATE Done SET span = 10800 WHERE id=362", nil, nil, nil) == SQLITE_OK {}
        if sqlite3_exec(db, "DELETE from Done WHERE id=407", nil, nil, nil) == SQLITE_OK {
            print("DELETE form Done WHERE id=407")
            return "ok"
        }else{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error update table: \(errmsg)")
            return errmsg
        }
            if sqlite3_exec(db, "UPDATE Done SET main = code/100", nil, nil, nil) == SQLITE_OK {
                return "ok"
            }else{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error update table: \(errmsg)")
                return errmsg
            }
        return "none"
    }
    
    func recreateTableDone()->String{
        //DROP TABLE IF EXIST
        if sqlite3_exec(db, "DROP TABLE IF EXISTS Done", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-\(errmsg)"
        }else{
            return createTableDone()
        }
    }
    
    func clearAll()->String{
        //DROP TABLE IF EXIST
        //DELETE FROM Done
        if sqlite3_exec(db, "DELETE FROM Done", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return errmsg
        }else{
            return "ok"
        }
    }
    func updateLastCode(newCode:Int, name:String)->String{
        var stmt: OpaquePointer?
        var queryString = "SELECT id, code FROM Done order by id desc limit 1"
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return errmsg
        }
        if (sqlite3_step(stmt) != SQLITE_ROW){
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return errmsg
        }
        let id = Int(sqlite3_column_int(stmt, 0))
        let code = Int(sqlite3_column_int(stmt, 1))
        if code == newCode{
            return "ok"
        }
        queryString = "UPDATE Done SET code = \(code),name='\(name)' WHERE id=\(id)"
        if sqlite3_exec(db, queryString, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return errmsg
        }
        return "ok"
    }
    
    func updateLastSpan(newSpan:Int)->String{
        var stmt: OpaquePointer?
        var queryString = "SELECT id,stop,span FROM Done order by id desc limit 1"
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-\(errmsg)"
        }
        if (sqlite3_step(stmt) != SQLITE_ROW){
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-\(errmsg)"
        }
        let id = Int(sqlite3_column_int(stmt, 0))
        let stop = Int(sqlite3_column_int(stmt, 1))
        let span = Int(sqlite3_column_int(stmt, 2))

        let newStop = stop - (span - newSpan)
        queryString = "UPDATE Done SET stop = \(newStop),span=\(newSpan) WHERE id=\(id)"
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-preparing insert: \(errmsg)"
        }
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-update done: \(errmsg)"
        }
        return "ok"
    }
    // @newSpan = -1
    // @desc = ""
    // @spnd = 0
    func updateLast(newSpan:Int, newDesc:String = "", newSpnd:Float=0.0)->String{
        var stmt: OpaquePointer?
        var queryString = "SELECT id,stop,span FROM Done order by id desc limit 1"
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            return "|-[error]-\(String(cString: sqlite3_errmsg(db)!))"
        }
        if (sqlite3_step(stmt) != SQLITE_ROW){
            return "|-[error]-\(String(cString: sqlite3_errmsg(db)!))"
        }
        let id = Int(sqlite3_column_int(stmt, 0))
        let stop = Int(sqlite3_column_int(stmt, 1))
        let span = Int(sqlite3_column_int(stmt, 2))
        //let spnd = Float(sqlite3_column_double(stmt, 3))
        //let desc = String(cString: sqlite3_column_text(stmt, 4))
        var msg = "|-[info]-"
        if newSpan > 60{
        let newStop = stop - (span - newSpan)
            queryString = "UPDATE Done SET stop = \(newStop),span=\(newSpan) WHERE id=\(id)"
            if sqlite3_exec(db, queryString, nil, nil, nil) == SQLITE_OK {
                msg += "set span=\(newSpan), "
            }else{
                return "|-[error]-" + String(cString: sqlite3_errmsg(db)!)
            }
        }
        if newDesc != "" || newSpnd > 0{
            queryString = "UPDATE Done SET desc = '\(newDesc)',spnd=\(newSpnd) WHERE id=\(id)"
            if sqlite3_exec(db, queryString, nil, nil, nil) == SQLITE_OK {
                msg += "spnd=\(newSpnd), desc=\(newDesc)"
            }else{
                return "|-[error]-" + String(cString: sqlite3_errmsg(db)!)
            }
        }
        return msg
    }
    
    func insert(item:TodoItem, start:Int, span:Int,spnd:Float,desc:String) -> String{
        var stmt: OpaquePointer?
        let main = item.code/100
        let queryString = "INSERT INTO Done (main,code,name,star,stop,span,spnd,desc) VALUES (\(main),\(item.code),'\(item.name)',\(start),strftime('%s','now'),\(span),\(spnd),'\(desc)')"
        //print(queryString)
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "|-[error]-\(errmsg)"
        }
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            return "failure inserting todo: \(errmsg)"
        }
        return "[\(item.code):\(item.name)] for \(Int(Float(span)*0.01666667)+1)mins \(spnd) \(desc) saved"
    }
    func getItemCount()->Int{
        let queryString = "SELECT count(id) FROM Done"
        //statement pointer
        var stmt:OpaquePointer?
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return -1
        }
        sqlite3_step(stmt)
        let c = Int(sqlite3_column_int(stmt, 0))
        return c
    }
    
    func getItem()->[DoneItem]{
        //this is our select query
        //
        let queryString = "SELECT id,code,name,star,stop,span,spnd,desc,main FROM Done"
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
            let star = Int(sqlite3_column_int(stmt, 3))
            let stop = Int(sqlite3_column_int(stmt, 4))
            let span = Int(sqlite3_column_int(stmt, 5))
            let spnd = Double(sqlite3_column_double(stmt, 6))
            let desc = String(cString: sqlite3_column_text(stmt, 7))
            //let main = Int(sqlite3_column_int(stmt, 8))
            let d = DoneItem(id:id,code:code,name:name,star:star,stop:stop,span:span,spnd:Float(spnd), alia:"", desc: desc)
            //print("[\(d.id)],m:\(main),c:\(d.code),n:\(d.name),s:\(d.star),e:\(d.stop),span:\(d.span)")
            doneList.append(d)
            a += 1
        }
        return doneList
    }
    func checkSpanSince(begin:Int) {
        
        let queryString = "SELECT code,name,star,stop,span,id FROM Done WHERE stop > \(begin) AND span > 7200 and main in (0,2) ORDER BY id,code"
        //statement pointer
        var stmt:OpaquePointer?
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("\(errmsg)")
        }
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let code = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let star = Int(sqlite3_column_int(stmt, 2))
            let stop = Int(sqlite3_column_int(stmt, 3))
            let sums = Double(sqlite3_column_int(stmt, 4))
            let id = Int(sqlite3_column_int(stmt, 5))
            print("id:\(id),code:\(code),name:\(name),[\(formateTime(i:star))~\(formateTime(i:stop))],span:\(sums/3600.0))")
        }
    }
    // calculate the amount of main class timespan for a peried time
    func sumMainClassSince(begin:Int)->[Int] {
        var aSum = [0,0,0,0,0,0,0]
        let queryString = "SELECT main,SUM(span) sums FROM Done WHERE star > \(begin) AND main < 7 GROUP BY main ORDER BY main"
        //statement pointer
        var stmt:OpaquePointer?
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("\(errmsg)")
            return aSum
        }
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let main = Int(sqlite3_column_int(stmt, 0))
            let sums = Int(sqlite3_column_int(stmt, 1))
            //print("m:\(main),s:\(sums)")
            aSum[main] = sums
        }
        return aSum
    }
    func intoMainClassSince(begin:Int) {
        let queryString = "SELECT code,SUM(span) sums FROM Done WHERE stop > \(begin) AND main < 7 GROUP BY code ORDER BY code"
        //statement pointer
        var stmt:OpaquePointer?
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("\(errmsg)")
        }
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let code = Int(sqlite3_column_int(stmt, 0))
            let sums = Double(sqlite3_column_int(stmt, 1))
            if sums > 0{
            print("code:\(code),span:\(sums/3600.0)")
            }
        }
    }
    func backupData() ->Int {
        // server endpoint
        let endpoint = "\(addr)/timepie/done"
        
        guard let endpointUrl = URL(string: endpoint) else {
            print("endpointUrl -1")
            return -1
        }
        var count = 0
        //Make JSON to send to send to server
        let encoder = JSONEncoder()
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
            return -1 * count
        }
        return count
    }


}
