//
//  InformationProvider.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/3/13.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import CoreData

class InformationProvider: Information {
    private init() {}
    
    //目前通过shared访问该类唯一实例
    static let shared: Information = InformationProvider()
    
    private lazy var context: NSManagedObjectContext = __context()
    
    public func add(personID: UInt, id: String, name: String, password: String, remark: String, attendance: String?, group: String?, image: UIImage?) -> Bool {
        let info = AdditionalPerson(context: context)
        info.personID = Int32(personID)
        info.id = id
        info.name = name
        info.passward = password
        info.remark = remark
        
        // 头像存储
        if let img = image {
            let _ = __imageSave(personID: personID, image: img)
        }
        
        // link and save
        do {
            if let atd = attendance {
                let attendances = try __searchAttendanceInfo(name: atd)
                if attendances.count != 1 {
                    return false
                } else {
                    let atd0 = attendances[0]
                    info.addToInAttendance(atd0)
                    atd0.addToForPerson(info)
                }
            }
            if let gp = group {
                let groups = try __searchGroupInfo(name: gp)
                if groups.count != 1 {
                    return false
                } else {
                    let gp0 = groups[0]
                    info.addToInGrounp(gp0)
                    gp0.addToPersons(info)
                }
            }
            
            try save()
            return true
        } catch {
            return false
        }
    }
    
    public func add(attendance: String, detail: String, startTime: Date, group: String) -> Bool {
        guard !attendance.isEmpty else {
            return false
        }
        
        let info = Attendance(context: context)
        info.name = attendance
        info.detail = detail
        info.startTime = startTime
        
        // link and save
        do {
            let groups = try __searchGroupInfo(name: group)
            if groups.count != 1 {
                return false
            } else {
                let gp = groups[0]
                info.forGrounp = gp
                gp.addToAttendances(info)
            }
            
            try save()
        } catch {
            return false
        }
        
        return true
    }
    
    public func add(group: String, detail: String) -> Bool {
        guard !group.isEmpty else {
            return false
        }
        
        let info = Group(context: context)
        info.name = group
        info.detail = detail
        
        do {
            try save()
        } catch {
            return false
        }
        
        return true
    }
    
    public func remove(personID: UInt) -> Bool {
        do {
            try __searchAdditionalInfo(personID: personID).forEach { additional in
                additional.inAttendance?.forEach {
                    ($0 as? Attendance)?.removeFromForPerson(additional)
                }
                additional.inGrounp?.forEach {
                    ($0 as? Group)?.removeFromPersons(additional)
                }
                context.delete(additional)
            }
            
            try save()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(attendance: String) -> Bool {
        do {
            try __searchAttendanceInfo(name: attendance).forEach { atd in
                atd.forPerson?.forEach {
                    ($0 as? AdditionalPerson)?.removeFromInAttendance(atd)
                }
                context.delete(atd)
            }
            
            try save()
            return true
        } catch {
            return false
        }
    }
    
    public func remove(group: String) -> Bool {
        do {
            try __searchGroupInfo(name: group).forEach { gp in
                gp.persons?.forEach {
                    ($0 as? AdditionalPerson)?.removeFromInGrounp(gp)
                }
                gp.attendances?.forEach {
                    let _ = remove(attendance: ($0 as? Attendance)?.name ?? "")
                }
                context.delete(gp)
            }
            
            try save()
            return true
        } catch {
            return false
        }
    }
    
    func personInfos() -> [AdditionalInfo]? {
        do {
            return try __searchAdditionalInfo().map { ad -> AdditionalInfo in
                return (personID: UInt(ad.personID), id: ad.id ?? "", name: ad.name ?? "", remark: ad.remark ?? "")
            }
        } catch {
            return nil
        }
    }
    
    func groupInfos() -> [GroupInfo]? {
        do {
            return try __searchGroupInfo().map { gp -> GroupInfo in
                return (name: gp.name ?? "", detail: gp.detail ?? "")
            }
        } catch {
            return nil
        }
    }
    
    func attendanceInfo(group: String) -> [AttendanceInfo]? {
        do {
            let groups = try __searchGroupInfo(name: group)
            guard groups.count == 1 else {
                return nil
            }
            return groups[0].attendances?.map{ attendance -> AttendanceInfo in
                if let atd = attendance as? Attendance {
                    return (name: atd.name ?? "", detail: atd.detail ?? "", startTime: atd.startTime ?? Date(timeIntervalSince1970: 0))
                } else {
                    return (name: "", detail: "", startTime: Date(timeIntervalSince1970: 0))
                }
            }
        } catch {
            return nil
        }
    }
    
    func personInfo(personID: UInt) -> AdditionalInfo? {
        /// TODO: 实现
        return nil
    }
    
    func personImage(personID: UInt) -> UIImage? {
        return UIImage(contentsOfFile: __imagePath(personID: personID))
    }
    
    func update(personID: UInt, id: String?, name: String?, password: String?, remark: String?, attendance: String?, group: String?, image: UIImage?) -> Bool {
        do {
            let additionals = try __searchAdditionalInfo(personID: personID)
            guard additionals.count == 1 else {
                return false
            }
            let additional = additionals[0]
            
            // 修改id、name、password、remark
            if let Id = id {
                additional.id = Id
            }
            if let ne = name {
                additional.name = ne
            }
            if let pw = password {
                additional.passward = pw
            }
            if let rm = remark {
                additional.remark = rm
            }
            
            // 添加attendance
            if let atd = attendance {
                let attendances = try __searchAttendanceInfo(name: atd)
                guard attendances.count == 1 else {
                    return false
                }
                let atd0 = attendances[0]
                additional.addToInAttendance(atd0)
                atd0.addToForPerson(additional)
            }
            
            // 添加group
            if let gp = group {
                let groups = try __searchGroupInfo(name: gp)
                guard groups.count == 1 else {
                    return false
                }
                let gp0 = groups[0]
                additional.addToInGrounp(gp0)
                gp0.addToPersons(additional)
            }
            
            // 修改头像
            if let img = image {
                let _ = __imageSave(personID: personID, image: img)
            }
            
            try save()
            return true
        } catch {
            return false
        }
    }
    
    /*
    public func searchAdditionalInfo(personID: UInt) -> [AdditionalInfo]? {
        do {
            return try __searchAdditionalInfo(personID: personID).map{
                mo -> AdditionalInfo in
                return (personID : personID, id : mo.id ?? "", password : mo.passward ?? "", remark : mo.remark ?? "", attendance: mo.included?.name ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAdditionalInfo(id: String) -> [AdditionalInfo]? {
        do {
            return try __searchAdditionalInfo(id: id).map {
                mo -> AdditionalInfo in
                return (personID : UInt(mo.personID), id : id, password : mo.passward ?? "", remark : mo.remark ?? "", attendance: mo.included?.name ?? "")
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(name: String, needPersonInfo: Bool) -> [AttendanceInfo]? {
        do {
            return try  __searchAttendanceInfo(name: name).map {
                mo -> AttendanceInfo in
                var additionalPerson = [AdditionalInfo]()
                if needPersonInfo {
                    mo.include?.forEach{ p in
                        if let person = p as? AdditionalPerson {
                            additionalPerson.append((personID: UInt(person.personID), id: person.id ?? "", password: person.passward ?? "", remark: person.remark ?? "", attendance: mo.name ?? ""))
                        }
                    }
                }
                return (name : name, detail : mo.detail ?? "", startTime : mo.startTime ?? Date(timeIntervalSince1970: 0), additionalPerson : additionalPerson)
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceInfo(startTime: Date, needPersonInfo: Bool) -> [AttendanceInfo]? {
        do {
            return try __searchAttendanceInfo(startTime: startTime).map {
                mo -> AttendanceInfo in
                var additionalPerson = [AdditionalInfo]()
                if needPersonInfo {
                    mo.include?.forEach{ p in
                        if let person = p as? AdditionalPerson {
                            additionalPerson.append((personID: UInt(person.personID), id: person.id ?? "", password: person.passward ?? "", remark: person.remark ?? "", attendance: mo.name ?? ""))
                        }
                    }
                }
                return (name : mo.name ?? "", detail : mo.detail ?? "", startTime : startTime, additionalPerson : additionalPerson)
            }
        } catch {
            return nil
        }
    }
    
    public func searchAttendanceNames() -> [String]? {
        do {
            return try __searchAttendanceInfo().map{ mo -> String in
                return mo.name ?? ""
            }
        } catch {
            return nil
        }
    }
    
    public func searchAdditionalNames(attendance: String) -> [String]? {
        if let infos = searchAttendanceInfo(name: attendance, needPersonInfo: true) {
            return infos.first?.additionalPerson.map{ info -> String in
                return info.id
            }
        } else {
            return nil
        }
    }
     */
}

extension InformationProvider {
    private static let timeZone = 8  // 东八区 China
    private static let model = "InformationModel"
    
    private static let userDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    private static let userImageDir = userDir + "/images/"
    
    private static let ImageQuality: CGFloat = 1.0
}

extension InformationProvider {
    public enum InformationError : Error {
        case saveError(info: String)
        case loadError(info: String)
    }
}

extension InformationProvider {
    fileprivate var localDate: Date {
        return Date().addingTimeInterval(Double(InformationProvider.timeZone) * 60 * 60)
    }
    
    fileprivate func save() throws {
        do {
            try context.save()
        } catch {
            throw InformationError.saveError(info: "save context")
        }
    }
    
    fileprivate func __context() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: InformationProvider.model)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if error != nil {
                fatalError("use name(\(String(describing: error))) to load context ")
            }
        })
        return container.viewContext
    }
    
    fileprivate func __searchAdditionalInfo(personID: UInt) throws -> [AdditionalPerson] {
        let fetchRequest: NSFetchRequest<AdditionalPerson> = AdditionalPerson.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "personID=\(personID)")
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use personID(\(personID)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAdditionalInfo(id: String) throws -> [AdditionalPerson] {
        let fetchRequest: NSFetchRequest<AdditionalPerson> = AdditionalPerson.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id=\"\(id)\"")
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use id(\(id)) to load additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAdditionalInfo() throws -> [AdditionalPerson] {
        let fetchRequest: NSFetchRequest<AdditionalPerson> = AdditionalPerson.fetchRequest()
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "load all additionalPerson NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(name: String) throws -> [Attendance] {
        guard name.count != 0 else {
            throw InformationError.loadError(info: "name is empty")
        }
        
        let fetchRequest: NSFetchRequest<Attendance> = Attendance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name=\"\(name)\"")
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use name(\(name)) to load Attendance NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo(startTime: Date) throws -> [Attendance] {
        let fetchRequest: NSFetchRequest<Attendance> = Attendance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime=\(startTime)")
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use startTime(\(startTime)) to load Attendance NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchAttendanceInfo() throws -> [Attendance] {
        let fetchRequest: NSFetchRequest<Attendance> = Attendance.fetchRequest()
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "load all Attendance NSManagedObjects")
        }
        
        return result
    }
    
    fileprivate func __searchGroupInfo(name: String) throws -> [Group] {
        guard name.count != 0 else {
            throw InformationError.loadError(info: "group name is empty")
        }
        
        let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name=\"\(name)\"")
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "use name(\(name)) to load Group NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __searchGroupInfo() throws -> [Group] {
        let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
        
        guard let result = try? context.fetch(fetchRequest) else {
            throw InformationError.loadError(info: "load all Group NSManagedObject")
        }
        
        return result
    }
    
    fileprivate func __imagePath(personID: UInt) -> String {
        return InformationProvider.userImageDir + "IMAGE_" + String(personID)
    }
    
    fileprivate func __imageSave(personID: UInt, image: UIImage) -> Bool {
        if let data = UIImageJPEGRepresentation(image, InformationProvider.ImageQuality) as NSData? {
            return data.write(toFile: __imagePath(personID: personID), atomically: true)
        } else {
            return false
        }
    }
}
