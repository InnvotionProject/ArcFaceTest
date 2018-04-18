//
//  RegisTableViewController.swift
//  ArcFaceTest
//
//  Created by jimmy233 on 2018/4/6.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit
import CoreData
class RegisTableViewController: UITableViewController {
    var Judge:Bool = false
    
    @IBAction func Scan(_ sender: Any) {
        Judge=true
    }
    
    @IBOutlet weak var Portrait: UIImageView!
    @IBOutlet weak var InputAgain: UITextField!
    @IBOutlet weak var Input: UITextField!
    @IBAction func Confirm(_ sender: Any) {
    let str_a = Input.text
    let str_b = InputAgain.text
    if(!(str_a?.isEmpty)! && !(str_b?.isEmpty)!)
    {
        if(str_a == str_b)
        {
         let person = info.personInfos()
        if(info.update(personID: (person?.last?.personID)!, id: nil, name: nil, password: str_a, remark: nil, attendance: nil, group: nil, image: nil))
            {
              print("update success")
            self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
    @IBOutlet weak var ProImage: UIImageView!
    @IBOutlet weak var RemarkInfo: UILabel!
    @IBOutlet weak var UserName: UILabel!
    @IBOutlet weak var ID: UILabel!

    

    @IBAction func Back(_ sender: UIBarButtonItem) {
        if let person = info.personInfos()
        {
        if(!person.isEmpty)
        {
            if(info.remove(personID: (person.last?.personID)!))
            {
             print("success remove")
            }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    let info=InformationProvider.shared
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    override func viewDidAppear(_ animated: Bool) {
        if(Judge==true)
        {
        let person = info.personInfos()
        print(person?.first?.id as Any)
        if let Ide = person?.last?.id
        {
            ID.text=Ide
        }
        if let Namee = person?.last?.name
        {
            UserName.text = Namee
        }
        if let Remarke = person?.last?.remark
        {
            RemarkInfo.text = Remarke
        }
        if let ProImagee = info.personImage(personID: (person?.last?.personID)!)
        {
            ProImage.image = ProImagee
        }
        else{
            ProImage.image=#imageLiteral(resourceName: "InitialFace")
            }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return 6
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "register_user" {
            if let camera = segue.destination as? CameraViewController {
                camera.setPurpose(purpose: .register)
            }
        }
    }

}
