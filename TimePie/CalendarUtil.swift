//
//  CalendarUtil.swift
//  TimePie
//
//  Created by lu wenbo on 2018/5/6.
//  Copyright © 2018 lu wenbo. All rights reserved.
//

import Foundation
import EventKit

class CalendarUtil{
    //static let AppleCalendar = CalendarUtil()
    //var eventStore:EKEventStore
    //var calendarForEvent:EKCalendar
    //var calendars:[EKCalendar]
    var hasCalendar:Bool
    
    public init(){
        //eventStore = EKEventStore()
        hasCalendar = false
    }
    
    func checkAuth()->Bool{
        let eventStore = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            return true
        case .denied:
            print("Access denied")
            return false
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: { (granted: Bool, NSError) -> Void in
                if granted {
                    print("Access Ok")
                }else{
                    print("Access denied")
                }
            })
        default:
            return false
        }
        return true
    }
    
    func getCalendarByNameOrDefault(eventStore:inout EKEventStore,calendar:String)->EKCalendar{
        
        let calendarForEvent = eventStore.defaultCalendarForNewEvents!
        
        let calendars = eventStore.calendars(for: EKEntityType.event) as [EKCalendar]
        hasCalendar = false
        for cal in calendars{
            print(cal.title)
            if cal.title == calendar{
                hasCalendar = true
                return cal
            }
        }
        return calendarForEvent
    }
    
    func getCalendarNotes(code:Int, desc:String,spnd:Float,span:Int)->String{
        var notes = "{\"code\":\(code),\"span\":\(Int(Double(span)/60.0))"
        if desc != "" {
            notes += ",\"desc\":\"\(desc)\""
        }
        if spnd > 0 {
            notes += ",\"spnd\":\(spnd)"
        }
        return notes + "}"
    }
    
    func addEventToCalendar(calendar:String, code:Int,title:String, start:Int,desc:String,spnd:Float,span:Int, stop:Int=0)->String{
        let auth = checkAuth()
        if !auth {
            return "|-[warn]-Not allowed to access Calendar"
        }
        var eventStore = EKEventStore()
        let calendar = getCalendarByNameOrDefault(eventStore: &eventStore, calendar: calendar)
        if !hasCalendar{
            //let tmpCal = EKCalendar(for: .event, eventStore: eventStore)
            //tmpCal.title = "timepie"
            //tmpCal.source = eventStore.defaultCalendarForNewEvents?.source
            //let ret = eventStore.saveCalendar(<#T##calendar: EKCalendar##EKCalendar#>, commit: <#T##Bool#>)
        }else{
            let doneEvent = EKEvent(eventStore: eventStore)
            doneEvent.calendar = calendar
            doneEvent.title = title
            doneEvent.startDate = Date(timeIntervalSince1970: Double(start))
            doneEvent.endDate =  stop == 0 ? Date() : Date(timeIntervalSince1970: Double(stop))
            
            
            doneEvent.notes = getCalendarNotes(code: code, desc: desc, spnd: spnd, span: span)
            do{
                try eventStore.save(doneEvent, span: .thisEvent, commit: true)
                //print("saved event id = \(doneEvent.eventIdentifier!)")
                return doneEvent.eventIdentifier!
                //stdUserDefaults.set(doneEvent.eventIdentifier, forKey: UserInfoKeys.lastApId)
            }catch{
                return "|-[error]-add Event to calendar failed!"
            }
        }
        return "|-[unknown]"
    }
    func updateLastCalendar(calendar:String,apId:String,code:Int,newSpan: Int, newDesc: String, newSpnd: Float)->String{
        let auth = checkAuth()
        if !auth {
            return "|-[warn]-Not allowed to access Calendar"
        }
        let eventStore = EKEventStore()
        //let cal = getCalendarByNameOrDefault(eventStore: &eventStore, calendar: calendar)
        //print(apId)
        let optEvent = eventStore.event(withIdentifier: apId)
        if optEvent == nil{
            return "|-[error]-not find event for \(apId)"
        }
        let event = optEvent!
        //try eventStore.remove(event, span: EKSpan.thisEvent, commit: true)
        var span = newSpan
        if newSpan < 0{
            let diff = Calendar.current.dateComponents([.hour,.minute,.second], from: event.startDate, to: event.endDate)
            span = diff.hour! * 3600 + diff.minute! * 60 + diff.second!
            print(span)
        }else{
            event.endDate = Calendar.current.date(byAdding: .second, value: newSpan, to: event.startDate)!
        }
        event.notes = getCalendarNotes(code: code, desc: newDesc, spnd: newSpnd, span: span)
        do{
            try eventStore.save(event, span: .thisEvent, commit: true)
            //print("update event id = \(event.eventIdentifier)")
            return event.eventIdentifier
        }catch{
            return "|-[error]-update Event to calendar failed!"
        }
        return "|-[unknown]"
    }
    
    
    
    
    
}











