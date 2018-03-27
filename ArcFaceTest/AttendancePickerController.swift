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
    var selected: String?
    
    static let buttonOK = "ok"
    static let buttonCancel = "cancel"
    static let titleName = "pick a attendance"
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "?????"
    }
    
    private func setup() {
        picker.delegate = self
        picker.dataSource = self
        self.title = AttendancePickerController.titleName + "\n\n\n\n\n\n\n\n\n"
        let pok = UIAlertAction(title: AttendancePickerController.buttonOK, style: .default) { action in
            self.selected = String(self.picker.selectedRow(inComponent: 0))
        }
        self.addAction(pok)
        self.addAction(UIAlertAction(title: AttendancePickerController.buttonCancel, style: .cancel, handler: nil))
        self.view.addSubview(picker)
    }
    
    override var preferredStyle: UIAlertControllerStyle {
        return .actionSheet
    }
}
