//
//  ViewController.swift
//  boundry
//
//  Created by Caroline Wong on 12/19/14.
//  Copyright (c) 2014 madebycaro. All rights reserved.
//

//left region
//37.7873589
//-122.421227

//right
//37.799889
//-122.413327



import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {    
    let apiKey = "AIzaSyBIGNgs-QTIXWdvFRgWp4KVhqYbLtS-5zE"
    var locManager = CLLocationManager()
    
    // gets eventName from EventTableViewController
    var eventName = ""
    
    // generates uniqueId for each phone
    let uniqueId = UIDevice.currentDevice().identifierForVendor.UUIDString
    // store all of the region names and if the user is in that region
    var regionDict = Dictionary<String, Bool>()
    var regions = Dictionary<String, AnyObject>()
    // store all of the region paths to periodically check which path the user is in
    var regionPathDict = Dictionary<String, GMSMutablePath>()
    var currentRegionIn = ""

    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var regionNameLabel: UILabel!
    @IBOutlet var coordLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("checkCurrentRegionIn"), userInfo: nil, repeats: true)
        locManager.delegate = self
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
        mapView.delegate = self
        mapView.myLocationEnabled = true
        mapView.settings.myLocationButton = true
        

//        getEventData(eventName)
    }

    //get api event info and show regions on view
//    @IBAction func getEventDataPressed(sender: AnyObject) {
//    }
    override func viewDidAppear(animated: Bool) {
        println("viewdidappear")
        getEventData(eventName)
    }
    
    func getEventData(evName: String) {
        if let events = NSUserDefaults().objectForKey("eventsData") as? [AnyObject] {
            for event in events {
                if let eventName = event["name"] as? NSString {
                    if eventName == evName {
                        if let regions = event["regions"] as? [AnyObject] {
                            for region in regions {
                                println("REGION")
                                println(region)
                                let regionName = region["region_name"] as NSString
                                self.regionDict[regionName] = false
                                if let regionAttr = region["region_attr"] as? [String: AnyObject]{
                                    if let coordinates = regionAttr["coordinates"] as? [AnyObject] {
                                        println("CC",coordinates)
                                        self.regions[regionName] = region
                                        dispatch_async(dispatch_get_main_queue(), {
                                            println("dispatch")
                                            self.eventNameLabel.text = eventName
                                            self.showRegion(coordinates, regName: regionName)
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //take coord array and create GMSPolygons on map
    func showRegion(regionCoordArray: NSArray, regName: NSString) {
        var regionPath = GMSMutablePath()
        var ind:UInt = 0

        //set regionPath coordinates
        for coord in regionCoordArray {
            var lat:CLLocationDegrees = coord["latitude"] as CLLocationDegrees!
            var lng:CLLocationDegrees = coord["longitude"] as CLLocationDegrees!
            var theCoord = CLLocationCoordinate2DMake(lat, lng)
            regionPath.insertCoordinate(theCoord, atIndex: ind)
            ind++
        }
        
        self.regionPathDict[regName] = regionPath
        
        var test = locManager
        NSLog("in here, %@", test)
        checkUserInBoundary(regionPath, regName: regName)
        
        var polygon = GMSPolygon(path: regionPath)
        polygon.strokeColor = UIColor.blackColor()
        polygon.strokeWidth = 2
        polygon.fillColor = UIColor.redColor().colorWithAlphaComponent(0.3)
        polygon.map = self.mapView
        polygon.title = regName
        polygon.tappable = true
    }
    
    //on tap of overlay, show region on label
    func mapView(mapView: GMSMapView!, didTapOverlay overlay: GMSOverlay!) {
        var obj = overlay
        regionNameLabel.text = obj.title
    }

    //check which region the user is in
    func checkCurrentRegionIn() {
        for (regName, regionPath) in regionPathDict {
            println("regPath")
            checkUserInBoundary(regionPath, regName: regName)
        }
    //go through all regions and do the checkUserInBoundary
        //if diff switch true and false and then do get request to server
    }
    
    //checks if user in any of the boundaries. updates label
    func checkUserInBoundary(region: GMSMutablePath, regName: NSString) {
        var regionId: String = ""
        if let latValue = locManager.location.coordinate.latitude as CLLocationDegrees? {
            if let lonValue = locManager.location.coordinate.longitude as CLLocationDegrees? {
//                println("setlatlon")
            }
        }
        var latValue = locManager.location.coordinate.latitude
        var lonValue = locManager.location.coordinate.longitude
        for (regNa, regObj) in regions {
            if (regNa == regName) {
                regionId = String(regObj["id"] as NSInteger!)
            }
        }
        
        //checks if current loc is in boundary
        if GMSGeometryContainsLocation(locManager.location.coordinate, region, true) {
            coordLabel.text = "You are in: " + regName
            //if false, switch to true and change the previous true to false
            //reassign currentRegionIn
            if regionDict[regName]! == false {
                regionDict[regName] = true
                if currentRegionIn != "" {
                    regionDict[currentRegionIn] = false
                }
                currentRegionIn = regName
                //get notifications for (newly) entered region and shows notification
//                var urlString = "http://boundry.herokuapp.com/api/mobile/actions/" + regName
                
                var urlString = "http://localhost:8000/api/mobile/actions/" + regionId
                let url = NSURL(string: urlString)
                let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                    
                    var parseError: NSError?
                    //AnyObject! gets rid of the Optional Wrapping
                    let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions.MutableContainers,
                        error:&parseError)
                    
                    //show notification that comes in for the event
                    if let notification = parsedObject[0] as? [String: AnyObject] {
                        println(notification)
                        var alert = UIAlertController(title: notification["name"] as? String, message: notification["action_data"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                task.resume()
            }
        }
    }
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        
        println(manager.location.coordinate.latitude)
        println(manager.location.coordinate.longitude)
        
        
        if let location = locations.first as? CLLocation {
            var latValue = manager.location.coordinate.latitude
            var lonValue = manager.location.coordinate.longitude
            
            var lng:String = "\(lonValue)"
            var lat:String = "\(latValue)"
            coordLabel.text = lat + " " + lng
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            //will continually get location unless have this line
            manager.stopUpdatingLocation()
        }
    }
    
//
//    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//        if status == .AuthorizedWhenInUse {
//            manager.startUpdatingLocation()
//            println(manager.location.coordinate.latitude)
//            println(manager.location.coordinate.longitude)
//            
//            mapView.myLocationEnabled = true
//            mapView.settings.myLocationButton = true
//        }
//    }
//

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

//        set timeout
//        let delayTime = 2 * Double(NSEC_PER_SEC)
//        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delayTime))
//        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
//            println("hi")
//        }