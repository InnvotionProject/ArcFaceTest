//
//  UserNameViewController.swift
//  ArcFaceTest
//
//  Created by jimmy233 on 2018/4/5.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit
protocol ReDelegate {
    func sendAgain(message:String)
}
class UserNameViewController: UIViewController,BackDelegate{
    func sendWord(message: String) {
        Change_name=message
        print(Change_name)
        self.delegate?.sendAgain(message: Change_name)
    }
    var Mid_name:String = ""
    var Change_name:String = ""
    var delegate:ReDelegate?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "ChangeName" {
            if let purpose = segue.destination as? UserNameTableViewController {
                purpose.Mid_na=Mid_name
                purpose.delegate=self
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

  

}
