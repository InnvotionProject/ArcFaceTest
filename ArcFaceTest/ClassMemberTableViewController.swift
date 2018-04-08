//
//  ClassMemberTableViewController.swift
//  ArcFaceTest
//
//  Created by 张睿恺 on 2018/4/7.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit
import CoreData
class ClassMemberTableViewController: UITableViewController {
    var classname:String? = ""
    
    let info = InformationProvider.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
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
        if let persons = info.personInfos(group: classname!)
        {
            return persons.count
        }
        else
        {
            return 0
        }
        //print("MystatisticsViewController --> persons: \(persons)")
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonInfo", for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
    private func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        if let persons = info.personInfos(group: classname!)
        {
        let person = persons[indexPath.row]
        // Configure the cell...
        if let profileCell = cell as? ProfileTableViewCell {
            // load data from database
            let personID = person.personID
            
            profileCell.profileImageView.image = info.personImage(personID: UInt(personID)) ?? #imageLiteral(resourceName: "InitialFace")
            profileCell.nameLabel.text = person.name
        }
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if let persons = info.personInfos(group: classname!)
            {
            let person = persons[indexPath.row]
            print("delete person with personId: \(person.personID)")
            if info.remove(personID: UInt(person.personID)) {
                //tableView.deleteRows(at: [indexPath], with: .fade)
                print("delete succeed")
            }
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
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
        if segue.identifier == "showSDetails" {
            guard let profileTMVC = segue.destination as? ProfileTableViewController else{
                fatalError("Unexpected destination")
            }
            guard let selectedProfileCell = sender as? ProfileTableViewCell else{
                fatalError("unexpected sender")
            }
            guard let indexPath = tableView.indexPath(for: selectedProfileCell) else{
                fatalError("the selected cell is not being dislplayed by the table")
            }
            
            if let persons = info.personInfos(group: classname!)
            {
            let person = persons[indexPath.row]
            let personID = person.personID
            //transport data to model
                profileTMVC.profileInfo = (image: info.personImage(personID: UInt(personID)) ?? #imageLiteral(resourceName: "InitialFace"), name: person.name, gender: "男", remark: person.remark )
            }
            
        } else if segue.identifier == "register_classmate" {
            if let camera = segue.destination as? CameraViewController {
                camera.setPurpose(purpose: .register)
                camera.setGroup(group: classname!)
                
            }
        }
    }

}

/*extension ClassMemberTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
        case .delete:
            if let deleteIndex = indexPath {
                tableView.deleteRows(at: [deleteIndex], with: .fade)
            }
        default:
            tableView.reloadData()
        }
    }
}*/



