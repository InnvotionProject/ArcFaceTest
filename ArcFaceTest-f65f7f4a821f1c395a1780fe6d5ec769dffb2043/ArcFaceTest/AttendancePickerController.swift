//
//  AttendancePickerController.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/3/27.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit

class AttendancePickerController: UIAlertController {
    var picker = UIPickerView()
    var callback: ((String) -> Void)?
    var attendances = [String]()
    
    static let buttonOK = "ok"
    static let buttonCancel = "cancel"
    static let titleName = "pick a attendance"
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.load()
        self.UIsetup()
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fit(bounds: CGRect, buttonH: CGFloat) {
        self.view.bounds = CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y,
            width: bounds.width,
            height: bounds.height - buttonH)
    }
}

extension AttendancePickerController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return attendances.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return attendances[row]
    }
    
    override var preferredStyle: UIAlertControllerStyle {
        return .actionSheet
    }
}

extension AttendancePickerController {
    fileprivate func UIsetup() {
        let frame = self.picker.frame
        let bounds = self.view.bounds
        picker.frame = frame.offsetBy(dx: (bounds.width - frame.width) / 4, dy: 0)
        self.view.addSubview(picker)
    }
    
    fileprivate func setup() {
        picker.delegate = self
        picker.dataSource = self
        self.title = AttendancePickerController.titleName + "\n\n\n\n\n\n\n\n\n"
        let pok = UIAlertAction(title: AttendancePickerController.buttonOK, style: .default) { action in
            let selected = self.picker.selectedRow(inComponent: 0)
            guard selected < self.attendances.count else {
                return
            }
            
            self.callback?(self.attendances[selected])
        }
        self.addAction(pok)
        self.addAction(UIAlertAction(title: AttendancePickerController.buttonCancel, style: .cancel, handler: nil))
    }
    
    fileprivate func load() {
        guard let attendances = Information.shared.searchAttendanceNames() else {
            return
        }
        
        self.attendances.append(contentsOf: attendances)
    }
}
