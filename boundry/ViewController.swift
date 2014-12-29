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
    

//    [{"eventName":"sampleEvent","regions":[{"regionName":"sampleRegion","coordinates":[[37.78705,-122.409188],[37.785901,-122.411334],[37.782291,-122.408976],[37.785505,-122.405334]]}]}]
    
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var clickButton: UIButton!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var coordLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
            eventNameLabel.text = "hi!!"
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
  
            mapView.delegate = self
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
            NSLog("in here")
        } else {
            NSLog("not in here")
        }
        
        NSLog("%@", rect)
            
       var polygon = GMSPolygon(path: rect)
        polygon.strokeColor = UIColor.blackColor()
        polygon.strokeWidth = 2
        polygon.fillColor = UIColor.redColor().colorWithAlphaComponent(0.3)
        polygon.map = self.mapView
        polygon.title = "Concert"
        polygon.tappable = true
        
        //if user in boundary, make label say in boundary name
        checkUserInBoundary()
    }
    
    func mapView(mapView: GMSMapView!, didTapOverlay overlay: GMSOverlay!) {
        var obj = overlay
        NSLog("%@", obj.title)
        var position = CLLocationCoordinate2DMake(locationManager.location.coordinate.latitude,locationManager.location.coordinate.longitude);
        var locMarker = GMSMarker(position: position)
        locMarker.title = obj.title
        locMarker.map = mapView
        
    }
    
    
    //checks if in any of the boundaries
    func checkUserInBoundary() {
//        NSLog("hi")
        var latValue = locationManager.location.coordinate.latitude
        var lonValue = locationManager.location.coordinate.longitude
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
//                    NSLog("%f, %f", locationManager.location.coordinate.longitude, locationManager.location.coordinate.latitude)
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

//get back an array of events = [{eventName: 'name', regions= []]
    
}