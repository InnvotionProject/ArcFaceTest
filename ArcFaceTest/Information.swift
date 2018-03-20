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
    
    private lazy var infoContext: NSManagedObjectContext = {
        let container = NSPersistentContainer(name: Information.model)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let e = error {
                fatalError("error when load information model")
            }
        })
        return container.viewContext
    }()
    
    public func add(personID: Int32, id: String, password: String, remark: String) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: Information.model, in: infoContext) else {
            return false
        }
        
        let info = NSManagedObject(entity: entity, insertInto: infoContext)
        info.setValue(personID, forKey: Information.additional_personID)
        info.setValue(id, forKey: Information.additional_id)
        info.setValue(password, forKey: Information.additional_password)
        info.setValue(remark, forKey: Information.additional_remark)
        
        self.save()
        
        return true
    }
    
    public func add(name: String, detail: String, startTime: Date) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: Information.model, in: infoContext) else {
            return false
        }
        
        let info = NSManagedObject(entity: entity, insertInto: infoContext)
        info.setValue(name, forKey: Information.attendance_name)
        info.setValue(detail, forKey: Information.attendance_detail)
        info.setValue(startTime, forKey: Information.attendance_startTime)
        
        self.save()
        
        return true
    }
    
    public func remove(personID: Int32, id: String, password: String, remark: String) -> Bool {
        return true
    }
    
    public func remove(name: String, detail: String, startTime: Date) -> Bool {
        return true
    }
    
    public func searchAdditionalInfo(by personID: Int32) -> [(personID: Int32, id: String, password: String, remark: String)] {
        return []
    }
    
    public func searchAdditionalInfo(by id: String) -> [(personID: Int32, id: String, password: String, remark: String)] {
        return []
    }
    
    public func searchAttendanceInfo(by name: String) -> [(name: String, detail: String, startTime: Date)] {
        return []
    }
    
    public func searchAttendanceInfo(by startTime: Date) -> [(name: String, detail: String, startTime: Date)] {
        return []
    }
}

extension Information {
    private static let timeZone = 8  // 东八区 China
    private static let model = "InformationModel"
    
    private static let additional_personID = "personID"
    private static let additional_id = "id"
    private static let additional_password = "password"
    private static let additional_remark = "remark"
    
    private static let attendance_name = "name"
    private static let attendance_detail = "detail"
    private static let attendance_startTime = "startTime"
}

extension Information {
    fileprivate var localDate: Date {
        return Date().addingTimeInterval(Double(Information.timeZone) * 60 * 60)
    }
    
    fileprivate func save() {
        do {
            try infoContext.save()
        } catch {
            fatalError("error when save recent objects")
        }
    }
}
