//
//  Information.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/3/13.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import CoreData

class Information {
    private init() {}
    
    //目前通过shared访问该类唯一实例
    static let shared = Information()
    
    private lazy var additionalPersonContext: NSManagedObjectContext = {
        return __context(name: Information.AdditionalPerson_model)
    }()
    
    private lazy var attendanceContext: NSManagedObjectContext = {
        return __context(name: Information.Attendance_model)
    }()
    
    public func add(personID: Int32, id: String, password: String, remark: String, attendance: String) -> Bool {
        let info = AdditionalPerson(context: additionalPersonContext)
        info.personID = personID
        info.id = id
        info.passward = password
        info.remark = remark
        
        // link
        do {
            let attendances = try __searchAttendanceInfo(name: attendance)
            if attendances.count != 1 {
                return false
            } else {
                let atd = attendances[0]
                info.included = atd
                atd.addToInclude(info)
            }
        } catch {
            return false
        }
        
        // save
        do {
            try additionalPersonSave()
        } catch {
            return false
        }
        
        return true
    }
    
    public func add(name: String, detail: String, startTime: Date) -> Bool {
        let info = Attendance(context: attendanceContext)
        info.name = name
        info.detail = detail
        info.startTime = startTime
        
        do {
            try attendanceSave()
        } catch {
            return false
        }
        
        return true
    }
    
    public func remove(personID: Int32) -> Bool {
        do {
            try __searchAdditionalInfo(personID: personID).forEach({ additional in
                additional.included?.removeFromInclude(additional)
                additionalPersonContext.delete(additional)
            })
            try additionalPersonSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(id: String) -> Bool {
        do {
            try __searchAdditionalInfo(id: id).forEach({ additional in
                additional.included?.removeFromInclude(additional)
                additionalPersonContext.delete(additional)
            })
            try additionalPersonSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(name: String) -> Bool {
        do {
            try __searchAttendanceInfo(name: name).forEach({ attendance in
                attendance.include?.forEach { p in
                    (p as? AdditionalPerson)?.included = nil
                }
                attendanceContext.delete(attendance)
            })
            try attendanceSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(startTime: Date) -> Bool {
        do {
            try __searchAttendanceInfo(startTime: startTime).forEach({ attendance in
                attendance.include?.forEach { p in
                    (p as? AdditionalPerson)?.included = nil
                }
                attendanceContext.delete(attendance)
            })
            try attendanceSave()
            return true
        } catch {
            return false
        }
    }
    
    public func searchAdditionalInfo(personID: Int32) -> [(personID: Int32, id: String, password: String, remark: String, attendance: String)]? {
        do {
            return try __searchAdditionalInfo(personID: personID).map{
                mo -> (personID : Int32, id : String, password : String, remark : String, attendance: String) in
                return (personID : personID, id : mo.id ?? "", password : mo.passward ?? "", remark : mo.remark ?? "", attendance: mo.included?.name ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAdditionalInfo(id: String) -> [(personID: Int32, id: String, password: String, remark: String, attendance: String)]? {
        do {
            return try __searchAdditionalInfo(id: id).map {
                mo -> (personID : Int32, id : String, password : String, remark : String, attendance: String) in
                return (personID : mo.personID, id : id, password : mo.passward ?? "", remark : mo.remark ?? "", attendance: mo.included?.name ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(name: String, needPersonInfo: Bool) -> [(name: String, detail: String, startTime: Date, additionalPerson: [(personID: Int32, id: String, password: String, remark: String, attendance: String)])]? {
        do {
            return try  __searchAttendanceInfo(name: name).map {
                mo -> (name : String, detail : String, startTime : Date, additionalPerson: [(personID: Int32, id: String, password: String, remark: String, attendance: String)]) in
                var additionalPerson = [(personID: Int32, id: String, password: String, remark: String, attendance: String)]()
                if needPersonInfo {
                    mo.include?.forEach{ p in
                        if let person = p as? AdditionalPerson {
                            additionalPerson.append((personID: person.personID, id: person.id ?? "", password: person.passward ?? "", remark: person.remark ?? "", attendance: mo.name ?? ""))
                        }
                    }
                }
                return (name : name, detail : mo.detail ?? "", startTime : mo.startTime ?? Date(timeIntervalSince1970: 0), additionalPerson : additionalPerson)
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(startTime: Date, needPersonInfo: Bool) -> [(name: String, detail: String, startTime: Date, additionalPerson: [(personID: Int32, id: String, password: String, remark: String, attendance: String)])]? {
        do {
            return try __searchAttendanceInfo(startTime: startTime).map {
                mo -> (name : String, detail : String, startTime : Date, additionalPerson: [(personID: Int32, id: String, password: String, remark: String, attendance: String)]) in
                var additionalPerson = [(personID: Int32, id: String, password: String, remark: String, attendance: String)]()
                if needPersonInfo {
                    mo.include?.forEach{ p in
                        if let person = p as? AdditionalPerson {
                            additionalPerson.append((personID: person.personID, id: person.id ?? "", password: person.passward ?? "", remark: person.remark ?? "", attendance: mo.name ?? ""))
                        }
                    }
                }
                return (name : mo.name ?? "", detail : mo.detail ?? "", startTime : startTime, additionalPerson : additionalPerson)
            }
        } catch {
            return nil
        }
    }
}

extension Information {
    private static let timeZone = 8  // 东八区 China
    private static let AdditionalPerson_model = "AdditionalPerson"
    private static let Attendance_model = "Attendance"
}

extension Information {
    public enum InformationError : Error {
        case saveError(info: String)
        case loadError(info: String)
    }
}

extension Information {
    fileprivate var localDate: Date {
        return Date().addingTimeInterval(Double(Information.timeZone) * 60 * 60)
    }
    
    fileprivate func additionalPersonSave() throws {
        do {
            try additionalPersonContext.save()
        } catch {
            throw InformationError.saveError(info: "save additional person")
        }
    }
    
    fileprivate func attendanceSave() throws {
        do {
            try attendanceContext.save()
        } catch {
            throw InformationError.saveError(info: "save attendance person")
        }
    }
    
    fileprivate func __context(name : String) -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if error != nil {
                fatalError("use name(\(String(describing: error))) to load context ")
            }
        })
        return container.viewContext
    }

    fileprivate func __searchAdditionalInfo(personID: Int32) throws -> [AdditionalPerson] {
        let fetchRequest: NSFetchRequest<AdditionalPerson> = AdditionalPerson.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "personID=\(personID)")
        
        guard let result = try? additionalPersonContext.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use personID(\(personID)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAdditionalInfo(id: String) throws -> [AdditionalPerson] {
        let fetchRequest: NSFetchRequest<AdditionalPerson> = AdditionalPerson.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id=\(id)")
        
        guard let result = try? additionalPersonContext.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use id(\(id)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(name: String) throws -> [Attendance] {
        let fetchRequest: NSFetchRequest<Attendance> = Attendance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name=\(name)")
        
        guard let result = try? attendanceContext.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use name(\(name)) to load Attendance NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(startTime: Date) throws -> [Attendance] {
        let fetchRequest: NSFetchRequest<Attendance> = Attendance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime=\(startTime)")
        
        guard let result = try? attendanceContext.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use startTime(\(startTime)) to load Attendance NSManagedObject")
        }
        
        return result
    }
}
