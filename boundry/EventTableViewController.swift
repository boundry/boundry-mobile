//
//  EventTableViewController.swift
//  boundry
//
//  Created by Jonathan Ng on 12/31/14.
//  Copyright (c) 2014 madebycaro. All rights reserved.
//

import UIKit

class EventTableViewController: UITableViewController, UITableViewDelegate {
    
    var eventsList = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Events"
        
        updateEventsList()
        
        fetchEventsData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //gets events data from server and saves to userdefaults
    func fetchEventsData() {
//        let url = NSURL(string: "http://boundry.herokuapp.com/api/mobile/events")
        let url = NSURL(string: "http://10.8.16.232:8000/api/mobile/events")

        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            
            var parseError: NSError?
            //AnyObject! gets rid of the Optional Wrapping
            let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
                options: NSJSONReadingOptions.MutableContainers,
                error:&parseError)
            
            let eventsData = parsedObject as [AnyObject]
            eventsData[0].setValue("", forKey: "event_center")
            
            NSUserDefaults.standardUserDefaults().setObject(eventsData, forKey: "eventsData")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            self.updateEventsList()
        }
        task.resume()
    }
    
    // update the events list view from the userdefaults
    func updateEventsList() {
        var newEventsList = [String]()
        
        if NSUserDefaults().objectForKey("eventsData") != nil {
            if let events = NSUserDefaults().objectForKey("eventsData")! as? NSArray {
                for event in events {
                    if let eventName = event.valueForKey("name") as NSString! {
                        newEventsList.append(eventName)
                        self.eventsList = newEventsList
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return eventsList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("event", forIndexPath: indexPath) as UITableViewCell

        cell.textLabel.text = eventsList[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }


    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "eventSegue") {
            var vc:ViewController = segue.destinationViewController as ViewController
            var selectedRowIndex = self.tableView.indexPathForSelectedRow()
            var currentCell = self.tableView.cellForRowAtIndexPath(selectedRowIndex!)
            vc.eventName = currentCell!.textLabel.text!
            println(vc.eventName)
        }
    }
}
