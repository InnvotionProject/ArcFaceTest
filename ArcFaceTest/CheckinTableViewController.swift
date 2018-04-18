//
//  CheckinTableViewController.swift
//  ArcFaceTest
//
//  Created by 张睿恺 on 2018/4/7.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit
import CoreData

class CheckinTableViewController: UITableViewController {
    
    var cname:String? = ""
    @IBAction func unwindToCheckIn(sender:UIStoryboardSegue)
    {
        if let sourceViewController = sender.source as? AddClassTableViewController, let classname = sourceViewController.classname.text , let remark = sourceViewController.classdetail.text {
            
            if(info.add(group: classname, detail: remark))
            {
                print("success")
            }
        }
        
    }
    
    fileprivate lazy var fetchedRequestsController: NSFetchedResultsController<Group> = {
        let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        
        let fetchRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: info.context, sectionNameKeyPath: nil, cacheName: nil)
     //   fetchRequestController.delegate = self
        return fetchRequestController
    }()
    
    private let info = InformationProvider.shared as! InformationProvider

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedRequestsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to perform fetch Request")
            print("\(fetchError)", "\(fetchError.localizedDescription)")
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         //self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        
        guard let groups = fetchedRequestsController.fetchedObjects else {return 0}
        //print("MystatisticsViewController --> persons: \(persons)")
        return groups.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Classinfo", for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
    private func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let person = fetchedRequestsController.object(at: indexPath)
        // Configure the cell...
        if let profileCell = cell as? ClassTableViewCell {
            // load data from database
           // let personID = person.name
            
            //profileCell.profileImageView.image = info.personImage(personID: UInt(personID)) ?? #imageLiteral(resourceName: "InitialFace")
            profileCell.Classname.text = person.name
            cname = person.name!
            
        }
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

    
    /*// Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let group = fetchedRequestsController.object(at: indexPath)
            print("delete person with personId: \(String(describing: group.name))")
            if info.remove(group: String(group.name)) {
                //tableView.deleteRows(at: [indexPath], with: .fade)
                print("delete succeed")
            }
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

    //In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "Passname" {
            
            guard let selectedProfileCell = sender as? ClassTableViewCell else{
                fatalError("unexpected sender")
            }
            guard let indexPath = tableView.indexPath(for: selectedProfileCell) else{
                fatalError("the selected cell is not being dislplayed by the table")
            }
            
            let person = fetchedRequestsController.object(at: indexPath)
            
            if let purpose = segue.destination as? ClassTableViewController{
                if let re = person.name
                {
                    purpose.Mid_name = re
                    // purpose.delegate=self
                }
               // fatalError("Unexpected destination")
            }
            
           
        }
    }
}


extension CheckinTableViewController: NSFetchedResultsControllerDelegate {
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
}



