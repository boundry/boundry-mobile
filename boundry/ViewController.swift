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
    var reloading = false
    
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
    
    @IBOutlet var reloadButton: UIButton!
    @IBOutlet var reloadSpinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("checkCurrentRegionIn"), userInfo: nil, repeats: true)
        self.title = self.eventName
        locManager.delegate = self
        locManager.startUpdatingLocation()
        mapView.delegate = self
        mapView.myLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    override func viewDidAppear(animated: Bool) {
        self.reloadData()
    }
    
    
    @IBAction func reloadData() {
        if (reloading) {
            return
        }
        self.coordLabel.alpha = 0.7
        self.reloadButton.alpha = 0.8
        self.reloadSpinner.hidden = false
        self.reloadSpinner.startAnimating()
        self.reloading = true
        
        self.regionPathDict.removeAll(keepCapacity: false)
        self.regionDict.removeAll(keepCapacity: false)
        self.regions.removeAll(keepCapacity: false)
        
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
            
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.clear()
                self.reloadSpinner.stopAnimating()
            })
            
            self.getEventData(self.eventName)
            self.reloading = false
        }
        task.resume()
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
    
    func getEventData(evName: String) {
        if let events = NSUserDefaults().objectForKey("eventsData") as? [AnyObject] {
            for event in events {
                if let eventName = event["name"] as? NSString {
                    if eventName == evName {
                        if let regions = event["regions"] as? [AnyObject] {
                            for region in regions {
                                let regionName = region["region_name"] as NSString
                                self.regionDict[regionName] = false
                                if let regionAttr = region["region_attr"] as? [String: AnyObject]{
                                    if let coordinates = regionAttr["coordinates"] as? [AnyObject] {
                                        self.regions[regionName] = region
                                        dispatch_async(dispatch_get_main_queue(), {
                                            self.title = eventName
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
        
        checkUserInBoundary(regionPath, regName: regName)
        
        var polygon = GMSPolygon(path: regionPath)
        
        //set the fill of the polygon
        var fill = regions[regName]?["region_attr"]??["fill"]?? as [String: AnyObject]
        polygon.fillColor = colorWithHexString(fill["color"] as String)
        polygon.fillColor = polygon.fillColor.colorWithAlphaComponent(fill["opacity"] as CGFloat)
        
        //set the stroke of the polygon
        var stroke = regions[regName]?["region_attr"]??["stroke"]?? as [String: AnyObject]
        polygon.strokeColor = colorWithHexString(stroke["color"] as String)
        polygon.strokeColor = polygon.strokeColor.colorWithAlphaComponent(stroke["opacity"] as CGFloat)
        polygon.strokeWidth = stroke["weight"] as CGFloat
        
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
            checkUserInBoundary(regionPath, regName: regName)
        }
    }
    
    //checks if user in any of the boundaries. updates label
    func checkUserInBoundary(region: GMSMutablePath, regName: NSString) {
        var regionId: String = ""

        if locManager.location == nil {
            return
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
                
                var urlString = "http://boundry.herokuapp.com/api/mobile/actions/" + regionId
                let url = NSURL(string: urlString)
                let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                    
                    var parseError: NSError?
                    //AnyObject! gets rid of the Optional Wrapping
                    let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions.MutableContainers,
                        error:&parseError)
                    
                    //show notification that comes in for the event
                    if parsedObject != nil {
                        if let notification = parsedObject[0] as? [String: AnyObject] {
                            if let title = notification["name"] as? String {
                                if let message = notification["action_data"] as? String {                                    
                                    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.Default, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                    
                                    self.regionDict[regName] = true

                                }
                            }
                        }
                    }
                }
                task.resume()
            }
        } else {
            if regName == self.currentRegionIn {
                self.currentRegionIn = "Not currently in a region"
                self.coordLabel.text = "Not currently in a region"
            }
        }
    }
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
//        println(manager.location.coordinate.latitude)
//        println(manager.location.coordinate.longitude)
        
        if let location = locations.first as? CLLocation {
            var latValue = manager.location.coordinate.latitude
            var lonValue = manager.location.coordinate.longitude
            
            var lng:String = "\(lonValue)"
            var lat:String = "\(latValue)"
//            coordLabel.text = lat + " " + lng
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            //will continually get location unless have this line
            manager.stopUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (countElements(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}