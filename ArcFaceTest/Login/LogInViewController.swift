//
//  LogInViewController.swift
//  ArcFaceTest
//
//  Created by 李博文 on 2018/4/19.
//  Copyright © 2018 王宇鑫. All rights reserved.
//

import UIKit

class LogInViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func unwindtoLogInViewController(segui: UIStoryboardSegue) {
        
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "register_manager" {
            if let register = segue.destination as? RegisPrepareViewController {
                register.setPurpose(purpose: .manager)
            }
        }
    }
}
