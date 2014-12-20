//
//  ViewController.swift
//  boundry
//
//  Created by Caroline Wong on 12/19/14.
//  Copyright (c) 2014 madebycaro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    let apiKey = "AIzaSyBIGNgs-QTIXWdvFRgWp4KVhqYbLtS-5zE"
    let locationManager = CLLocationManager()
    
    var rect = GMSMutablePath()

    
//    GMSMutablePath *rect = [GMSMutablePath path];
//    [rect addCoordinate:CLLocationCoordinate2DMake(37.36, -122.0)];
//    [rect addCoordinate:CLLocationCoordinate2DMake(37.45, -122.0)];
//    [rect addCoordinate:CLLocationCoordinate2DMake(37.45, -122.2)];
//    [rect addCoordinate:CLLocationCoordinate2DMake(37.36, -122.2)];
//    
//    // Create the polygon, and assign it to the map.
//    GMSPolygon *polygon = [GMSPolygon polygonWithPath:rect];
//    polygon.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:0.05];
//    polygon.strokeColor = [UIColor blackColor];
//    polygon.strokeWidth = 2;
//    polygon.map = mapView_;
//    
    
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var clickButton: UIButton!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var coordLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
            eventNameLabel.text = "hi!!"
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func clickPressed(sender: AnyObject) {
        
        NSLog("button pressed")
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
                    NSLog("%f, %f", locationManager.location.coordinate.longitude, locationManager.location.coordinate.latitude)
            var latValue = locationManager.location.coordinate.latitude
            var lonValue = locationManager.location.coordinate.longitude
            
            var lng:String = "\(lonValue)"
            var lat:String = "\(latValue)"
            coordLabel.text = lat + " " + lng
            
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
    
            locationManager.stopUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//get back an array of events = [{eventName: 'name', regions= []]
    
}