//
//  ViewController.swift
//  Werkstuk2Augustus
//
//  Created by Fady Elabed on 14/08/2019.
//  Copyright © 2019 Fady Elabed. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var SavedArray:[PolylineSaved] = []

    var locationManager = CLLocationManager()

    @IBAction func btnRefresh(_ sender: Any) {
        refreshMap()
    }
    
    @IBOutlet weak var mapView: MKMapView!

    func refreshMap() {
        refreshStrokeline()
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        
        self.mapView.removeOverlays(mapView.overlays)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        
        refreshMap()
    }

    func refreshStrokeline() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let url = URL(string: "https://opendata.brussels.be/api/records/1.0/search/?dataset=traffic-volume&facet=level_of_service")
        let urlRequest = URLRequest(url: url!)
        
        let session = URLSession(configuration:
            URLSessionConfiguration.default)
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            
            // check for errors
            guard error == nil else {
                print("error calling GET")
                print(error!)
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(
                    with: responseData, options: [])
                    as? [String: AnyObject] else {
                        print("error trying to convert data to JSON")
                        return
                }
                
                let records = json["records"] as? [Any]
                
                for record in records! {
                    
                    var points = [CLLocationCoordinate2D]()
                    
                    let rec = record as? [String: AnyObject]
                    let fields = rec!["fields"] as? [String: AnyObject]
                    let geo_shape = fields!["geo_shape"] as? [String: AnyObject]
                    let couleur = fields!["level_of_service"] as? String
                    let coordinates = geo_shape!["coordinates"] as? [Any]
                    
                    for coordinate in coordinates!{
                        
                        let coordinateOk = coordinate as? [Double]
                        
                        //     print(coordinateOk!)
                        
                        let point = CLLocationCoordinate2D(latitude: coordinateOk![1], longitude: coordinateOk![0])
                        
                        
                        points.append(point)
                        
                        
                    }
                    
                    // print(couleur!)
                    
                    let polyline = CustomPolyline(coordinates: points, count: points.count)
                    polyline.color = couleur!
                    
                    let PolylineSaveData = NSEntityDescription.insertNewObject(forEntityName: "PolylineSaved", into: managedContext) as! PolylineSaved
                    
                    PolylineSaveData.color = couleur!
                    PolylineSaveData.polyline = coordinates! as NSObject
                    
                    //  print("PolylineSavecolor:")
                    //  print(PolylineSaveData.color!)
                    
                    do {
                        try managedContext.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                    
                    
                    self.mapView.addOverlays([polyline])
                    self.mapView.centerCoordinate = points[0]
                    self.mapView.region = MKCoordinateRegion(center: points[0], span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
                    
                }
                
                DispatchQueue.main.async {
                    self.haalUitCoreData()
                }
                
                
            } catch {
                print("error")
            }
            
        }
        task.resume()
        
        
    }
    func haalUitCoreData() {
        
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchPolylineCoordinates =
            NSFetchRequest<NSFetchRequestResult>(entityName: "PolylineSaved")
        //3
        do {
            self.SavedArray = try managedContext.fetch(fetchPolylineCoordinates) as! [PolylineSaved]
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        print(self.SavedArray[1].color!)
        print(self.SavedArray[1].polyline!)
        
        
    }
    
    
}
