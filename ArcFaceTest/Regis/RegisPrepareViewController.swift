//
//  RegisPrepareViewController.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/4/20.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit

class RegisPrepareViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var purpose = RegisTableViewController.Purpose.none
    private var group: String?
    private var attendance: String?
    
    func setPurpose(purpose: RegisTableViewController.Purpose) {
        self.purpose = purpose
    }
    
    func setGroup(group: String?) {
        self.group = group
    }
    
    func setAttendance(attendance: String?) {
        self.attendance = attendance
    }
}

extension RegisPrepareViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let register = viewController as? RegisTableViewController {
            register.setPurpose(purpose: self.purpose)
            register.setGroup(group: self.group)
            register.setAttendance(attendance: self.attendance)
        }
    }
}
