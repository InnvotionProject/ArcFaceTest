//
//  Information.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/4/3.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import CoreData

/**
 使用该Information，请使用实现了该协议的provider，调用其shared。
 
 如：let info = InformationProvider.shared
 */
protocol Information {
    /**
     添加一个person
     
     - parameters:
        - personID:  全局唯一标识符，32位整型
        - id:        person的ID
        - name:      名字
        - password:  密码（如果有）
        - remark:    额外说明
        - attendance:参加的考勤（可空）
        - group:     所在的group（可空）
     - returns:
        返回是否成功 Bool
     */
    func add(personID: UInt, id: String, name: String, password: String, remark: String, attendance: String?, group: String?) -> Bool
    
    /**
     添加一个attendance
     
     - parameters:
        - attendance:名字
        - detail:    详细信息
        - startTime: 开始日期
        - group:     所属group
     - returns:
        返回是否成功 Bool
     */
    func add(attendance: String, detail: String, startTime: Date, group: String) -> Bool
    
    /**
     添加一个group
     
     - parameters:
        - group: 名字
        - detail:详细信息
     - returns:
        返回是否成功 Bool
     */
    func add(group: String, detail: String) -> Bool
    
    /**
     删除一个person信息
     
     - parameter personID: person的全局唯一标识符
     - returns:
        返回是否成功 Bool
     */
    func remove(personID: UInt) -> Bool
    
    /**
     删除一个attendance信息
     
     - parameter attendance: attendance的名字
     - returns:
        返回是否成功 Bool
     */
    func remove(attendance: String) -> Bool
    
    /**
     删除一个group信息，会顺带删除它所包含的attendance
     
     - parameter group: group的名字
     - returns:
        返回是否成功 Bool
     */
    func remove(group: String) -> Bool
    
    /**
     获取所有person信息
     
     - returns:
        所有person信息
     */
    func personInfos() -> [AdditionalInfo]?
    
    /**
     获取所有group信息
     
     - returns:
        所有group信息
     */
    func groupInfos() -> [GroupInfo]?
    
    /**
     获取一个group下的所有attendance信息
     
     - parameter group: group的名字
     - returns:
        所有attendance信息
     */
    func attendanceInfo(group: String) -> [AttendanceInfo]?
}

extension Information {
    typealias AdditionalInfo = (personID: UInt, id: String, name: String, remark: String)
    typealias AttendanceInfo = (name: String, detail: String, startTime: Date)
    typealias GroupInfo = (name: String, detail: String)
}
