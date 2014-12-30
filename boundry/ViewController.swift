//
//  ViewController.swift
//  boundry
//
//  Created by Caroline Wong on 12/19/14.
//  Copyright (c) 2014 madebycaro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    let apiKey = "AIzaSyBIGNgs-QTIXWdvFRgWp4KVhqYbLtS-5zE"
    let locationManager = CLLocationManager()
    
    @IBOutlet var getEventButton: UIButton!
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var clickButton: UIButton!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var regionNameLabel: UILabel!
    @IBOutlet var coordLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
            eventNameLabel.text = "hi!!"
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
  
            mapView.delegate = self
    }

    @IBAction func getEventDataPressed(sender: AnyObject) {
        
        let url = NSURL(string: "http://boundry.herokuapp.com/api/mobile/events")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            
            var parseError: NSError?
            //AnyObject! gets rid of the Optional Wrapping
            let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
                options: NSJSONReadingOptions.MutableContainers,
                error:&parseError)
          
//            println(parsedObject)

            if let event = parsedObject[0] as? NSDictionary {
                if let eventName = event["eventName"] as? NSString {
//                    println(eventName)
                    if let regions = event["regions"] as? NSArray {
                        //for every region, show region on map
                        for region in regions {
                            if let regionName = region.valueForKey("regionName") as NSString! {
//                                println(regionName)
                                var allCoord = region.objectForKey("coordinates") as NSArray!
                                //displays region on map
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.showRegion(allCoord, regName: regionName)
                                })
//                                //individual coord for region
//                                for coord in allCoord {
//                                    println(coord)
//                                }
//                            println(region["coordinates"])
//                            showRegion(region)
                            }
                        }
                        
//                        println(regions["regionName"])
//                        if let regionName = event.valueForKey("regionName") as? NSString {
//                                println(regionName)
//                            
//                        }
//                        println(regions[0])
                        
                    }
                    
                }
            }
        }
        task.resume()
    }
    
    func showRegion(regionCoordArray: NSArray, regName: NSString) {
        var regionPath = GMSMutablePath()
        var ind:UInt = 0

        //set regionPath coordinates
        for coord in regionCoordArray {
            var lat:CLLocationDegrees = coord[0] as CLLocationDegrees!
            var lng:CLLocationDegrees = coord[1] as CLLocationDegrees!
            var theCoord = CLLocationCoordinate2DMake(lat, lng)
            regionPath.insertCoordinate(theCoord, atIndex: ind)
            ind++
        }
        checkUserInBoundary(regionPath, regName: regName)
        
        var polygon = GMSPolygon(path: regionPath)
        polygon.strokeColor = UIColor.blackColor()
        polygon.strokeWidth = 2
        polygon.fillColor = UIColor.redColor().colorWithAlphaComponent(0.3)
        polygon.map = self.mapView
        polygon.title = regName
        polygon.tappable = true
        
    }
    @IBAction func clickPressed(sender: AnyObject) {
        var firstCoord = CLLocationCoordinate2DMake(37.78705,-122.409188)
        var secCoord = CLLocationCoordinate2DMake(37.785901,-122.411334)
        var thirdCoord = CLLocationCoordinate2DMake(37.782291,-122.408976)
        var fourthCoord = CLLocationCoordinate2DMake(37.785505,-122.405334)
        
        var rect = GMSMutablePath()
        rect.insertCoordinate(firstCoord, atIndex: 0)
        rect.insertCoordinate(secCoord, atIndex: 1)
        rect.insertCoordinate(thirdCoord, atIndex: 2)
        rect.insertCoordinate(fourthCoord, atIndex: 3)

        
        var currentLoc = CLLocationCoordinate2D(latitude: locationManager.location.coordinate.latitude, longitude: locationManager.location.coordinate.longitude)
        
        //checks if current loc is in boundary
        if GMSGeometryContainsLocation(currentLoc, rect, true) {
            println("in here")
        } else {
            println("not in here")
        }
        
//        println(rect)
        
//       var polygon = GMSPolygon(path: rect)
//        polygon.strokeColor = UIColor.blackColor()
//        polygon.strokeWidth = 2
//        polygon.fillColor = UIColor.redColor().colorWithAlphaComponent(0.3)
//        polygon.map = self.mapView
//        polygon.title = "Concert"
//        polygon.tappable = true
        
        //if user in boundary, make label say in boundary name
//        checkUserInBoundary()
    }
    
    func mapView(mapView: GMSMapView!, didTapOverlay overlay: GMSOverlay!) {
        var obj = overlay
        regionNameLabel.text = obj.title
    }

    
    //checks if in any of the boundaries
    func checkUserInBoundary(region: GMSMutablePath, regName: NSString) {
        
        
        var latValue = locationManager.location.coordinate.latitude
        var lonValue = locationManager.location.coordinate.longitude
        
        //checks if current loc is in boundary
        if GMSGeometryContainsLocation(locationManager.location.coordinate, region, true) {
            coordLabel.text = "You are in: " + regName
            println("in here")
        } else {
            println("not in here")
        }
       
//        NSLog("%f, %f", latValue, lonValue)
    
    }

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    
        if status == .AuthorizedWhenInUse {
    
            locationManager.startUpdatingLocation()
            
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            var latValue = locationManager.location.coordinate.latitude
            var lonValue = locationManager.location.coordinate.longitude
            
            var lng:String = "\(lonValue)"
            var lat:String = "\(latValue)"
            coordLabel.text = lat + " " + lng
            
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            //will continually get location unless have this line
            locationManager.stopUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}