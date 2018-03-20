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
    
    private func fetchRequest(entityName : String, predicate : NSPredicate) -> NSFetchRequest<NSFetchRequestResult> {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        return fr
    }
    
    public func add(personID: Int32, id: String, password: String, remark: String) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: Information.AdditionalPerson_model, in: additionalPersonContext) else {
            return false
        }
        
        let info = NSManagedObject(entity: entity, insertInto: additionalPersonContext)
        info.setValue(personID, forKey: Information.additional_personID)
        info.setValue(id, forKey: Information.additional_id)
        info.setValue(password, forKey: Information.additional_password)
        info.setValue(remark, forKey: Information.additional_remark)
        
        do {
            try additionalPersonSave()
        } catch {
            return false
        }
        
        return true
    }
    
    public func add(name: String, detail: String, startTime: Date) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: Information.Attendance_model, in: attendanceContext) else {
            return false
        }
        
        let info = NSManagedObject(entity: entity, insertInto: attendanceContext)
        info.setValue(name, forKey: Information.attendance_name)
        info.setValue(detail, forKey: Information.attendance_detail)
        info.setValue(startTime, forKey: Information.attendance_startTime)
        
        do {
            try attendanceSave()
        } catch {
            return false
        }
        
        return true
    }
    
    public func remove(personID: Int32) -> Bool {
        do {
            try __searchAdditionalInfo(personID: personID).forEach({ mo in
                additionalPersonContext.delete(mo)
            })
            try additionalPersonSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(id: String) -> Bool {
        do {
            try __searchAdditionalInfo(id: id).forEach({ mo in
                additionalPersonContext.delete(mo)
            })
            try additionalPersonSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(name: String) -> Bool {
        do {
            try __searchAttendanceInfo(name: name).forEach({ mo in
                attendanceContext.delete(mo)
            })
            try attendanceSave()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(startTime: Date) -> Bool {
        do {
            try __searchAttendanceInfo(startTime: startTime).forEach({ mo in
                attendanceContext.delete(mo)
            })
            try attendanceSave()
            return true
        } catch {
            return false
        }
    }
    
    public func searchAdditionalInfo(personID: Int32) -> [(personID: Int32, id: String, password: String, remark: String)]? {
        do {
            return try __searchAdditionalInfo(personID: personID).map{
                mo -> (personID : Int32, id : String, password : String, remark : String) in
                let id = mo.value(forKey: Information.additional_id) as? String
                let password = mo.value(forKey: Information.additional_password) as? String
                let remark = mo.value(forKey: Information.additional_remark) as? String
                return (personID : personID, id : id ?? "", password : password ?? "", remark : remark ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAdditionalInfo(id: String) -> [(personID: Int32, id: String, password: String, remark: String)]? {
        do {
            return try __searchAdditionalInfo(id: id).map {
                mo -> (personID : Int32, id : String, password : String, remark : String) in
                let personID = mo.value(forKey: Information.additional_personID) as? Int32
                let password = mo.value(forKey: Information.additional_password) as? String
                let remark = mo.value(forKey: Information.additional_remark) as? String
                return (personID : personID ?? -1, id : id, password : password ?? "", remark : remark ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(name: String) -> [(name: String, detail: String, startTime: Date)]? {
        do {
            return try  __searchAttendanceInfo(name: name).map {
                mo -> (name : String, detail : String, startTime : Date) in
                let detail = mo.value(forKey: Information.attendance_detail) as? String
                let startTime = mo.value(forKey: Information.attendance_startTime) as? Date
                return (name : name, detail : detail ?? "", startTime : startTime ?? Date(timeIntervalSince1970: 0))
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(startTime: Date) -> [(name: String, detail: String, startTime: Date)]? {
        do {
            return try __searchAttendanceInfo(startTime: startTime).map {
                mo -> (name : String, detail : String, startTime : Date) in
                let name = mo.value(forKey: Information.attendance_name) as? String
                let detail = mo.value(forKey: Information.attendance_detail) as? String
                return (name : name ?? "", detail : detail ?? "", startTime : startTime)
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
    
    private static let additional_personID = "personID"
    private static let additional_id = "id"
    private static let additional_password = "password"
    private static let additional_remark = "remark"
    
    private static let attendance_name = "name"
    private static let attendance_detail = "detail"
    private static let attendance_startTime = "startTime"
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

    fileprivate func __searchAdditionalInfo(personID: Int32) throws -> [NSManagedObject] {
        let fetchRequest = self.fetchRequest(entityName: Information.AdditionalPerson_model, predicate: NSPredicate(format: "personID=\(personID)"))
        
        guard let result = (try? additionalPersonContext.fetch(fetchRequest)) as? [NSManagedObject] else {
            throw InformationError.loadError(info: "use personID(\(personID)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAdditionalInfo(id: String) throws -> [NSManagedObject] {
        let fetchRequest = self.fetchRequest(entityName: Information.AdditionalPerson_model, predicate: NSPredicate(format: "id=\(id)"))
        
        guard let result = (try? additionalPersonContext.fetch(fetchRequest)) as? [NSManagedObject] else {
            throw InformationError.loadError(info: "use id(\(id)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(name: String) throws -> [NSManagedObject] {
        let fetchRequest = self.fetchRequest(entityName: Information.Attendance_model, predicate: NSPredicate(format: "name=\(name)"))
        
        guard let result = (try? attendanceContext.fetch(fetchRequest)) as? [NSManagedObject] else {
            throw InformationError.loadError(info: "use name(\(name)) to load Attendance NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(startTime: Date) throws -> [NSManagedObject] {
        let fetchRequest = self.fetchRequest(entityName: Information.Attendance_model, predicate: NSPredicate(format: "startTime=\(startTime)"))
        
        guard let result = (try? attendanceContext.fetch(fetchRequest)) as? [NSManagedObject] else {
            throw InformationError.loadError(info: "use startTime(\(startTime)) to load Attendance NSManagedObject")
        }
        
        return result
    }
}
