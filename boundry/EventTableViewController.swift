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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func removeNullsInJSON(json: AnyObject) {
        if var array = json as? NSMutableArray {
            for value in array {
                self.removeNullsInJSON(value)
            }
        }
        
        if var dictionary = json as? NSMutableDictionary {
            for (key, value) in dictionary {
                if value is NSNull {
                    dictionary.setValue("", forKey: key as String)
                    continue
                }
                
                self.removeNullsInJSON(value)
            }
        }
    }
    
    //gets events data from server and saves to userdefaults
    func fetchEventsData() {
        let url = NSURL(string: "http://boundry.herokuapp.com/api/mobile/events")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            
            var parseError: NSError?
            //AnyObject! gets rid of the Optional Wrapping
            let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
                options: NSJSONReadingOptions.MutableContainers,
                error:&parseError)
            
            if parsedObject == nil {
                return
            }
            
            let eventsData = parsedObject as NSMutableArray
            
            self.removeNullsInJSON(eventsData)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "eventSegue") {            
            var vc:ViewController = segue.destinationViewController as ViewController
            var selectedRowIndex = self.tableView.indexPathForSelectedRow()
            var currentCell = self.tableView.cellForRowAtIndexPath(selectedRowIndex!)
            vc.eventName = currentCell!.textLabel.text!
        }
    }
}
