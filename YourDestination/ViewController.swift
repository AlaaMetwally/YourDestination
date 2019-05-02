//
//  ViewController.swift
//  YourDestination
//
//  Created by Geek on 4/22/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import UserNotifications

class ViewController: UIViewController, GMSMapViewDelegate {
    
    let locationManager = CLLocationManager()
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    var currentLocation: CLLocation?
    let path = GMSMutablePath()
    var array: [[String:Any]] = []
    var destName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startUpdatingLocation()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func scheduleNotifications(message: String) {
        let content = UNMutableNotificationContent()
        content.badge = 1
        content.title = "This notification is to inform you "
        content.subtitle = "that you are about 1 km from your nearby places"
        content.body = "\(message)"
        content.categoryIdentifier = "actionCategory"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 3.0, repeats: false)
        
        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error:Error?) in
            if error != nil {
                print(error?.localizedDescription)
            }
            print("Notification Register Success")
        }
    }
    
    func startUpdatingLocation(){
        placesClient = GMSPlacesClient.shared()
        DispatchQueue.main.async {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.distanceFilter = 50
            self.locationManager.startUpdatingLocation()
            self.locationManager.delegate = self
        }
    }
    
    func placeConfiguration(){
        DispatchQueue.main.async {
            let camera = GMSCameraPosition.camera(withLatitude: (self.locationManager.location?.coordinate.latitude)!, longitude:(self.locationManager.location?.coordinate.longitude)!, zoom: self.zoomLevel)
            self.mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
            self.mapView.delegate = self
            self.mapView.isMyLocationEnabled = true
            self.mapView.settings.myLocationButton = true
            self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add the map to the view, hide it until we've got a location update.
            self.view.addSubview(self.mapView)
            self.mapView.isHidden = true
            
            self.placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
                if let error = error {
                    print("Current Place error: \(error.localizedDescription)")
                    return
                }
                
                if let placeLikelihoodList = placeLikelihoodList {
                    let place = placeLikelihoodList.likelihoods.first?.place
                    if let place = place {
                        DispatchQueue.main.async {
                            let location = CLLocationCoordinate2D(latitude: self.locationManager.location?.coordinate.latitude as! CLLocationDegrees, longitude: self.locationManager.location?.coordinate.longitude as!CLLocationDegrees)
                            let marker = GMSMarker(position: location)
                            marker.snippet = place.formattedAddress as? String
                            marker.title = place.name as? String
                            marker.map = self.mapView
                        }
                    }
                }
            })
            self.locationManagerConfiguration()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func locationManagerConfiguration(){
        var methodParameters = [
            Constants.DestinationParameterKeys.APIKey : Constants.DestinationParameterValues.APIKey,
            Constants.DestinationParameterKeys.sensor : Constants.DestinationParameterValues.sensor,
            ] as [String : Any]
        let sourceCoordinates = self.locationManager.location?.coordinate
        let lat = sourceCoordinates?.latitude
        let lon = sourceCoordinates?.longitude
        methodParameters[Constants.DestinationParameterKeys.location] = "\(lat!),\(lon!)"
        
        Constants.Types.allCases.forEach{
            methodParameters[Constants.DestinationParameterKeys.type] = $0.rawValue
            Constants.Radius.allCases.forEach{
                methodParameters[Constants.DestinationParameterKeys.radius] = $0.rawValue
                let url = self.destinationURLFromParameters(methodParameters as [String : AnyObject])
                let request = URLRequest(url: url)
                self.requestHandler(request: request){ (results,error) in
                    print(results)
                    var name = self.getDataFromRequest(results: results)
                    name = String(name.dropLast())
                     UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["notif"])
                    if(name != ""){
                        self.scheduleNotifications(message: name)
                    }
                }
            }
        }
    }
    
    func getDataFromRequest(results: [[String:Any]]?) -> String{
        
        guard let destArray = results, destArray.count != 0 else{
            print("Could not parse the array for destination")
            return ""
        }
        let coordinate0 = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        
        let sourceCoordinates = locationManager.location?.coordinate
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinates!)
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let directionRequest = MKDirections.Request()
        
        for dest in destArray{
            let destinatioCoordinates = CLLocationCoordinate2DMake(dest["lat"] as! CLLocationDegrees, dest["lng"] as! CLLocationDegrees)
            let destnationPlacemark = MKPlacemark(coordinate: destinatioCoordinates)
            let destItem = MKMapItem(placemark: destnationPlacemark)
            
            directionRequest.source = sourceItem
            directionRequest.destination = destItem
            directionRequest.transportType = .automobile
            
            let coordinate1 = CLLocation(latitude: dest["lat"] as! CLLocationDegrees, longitude: dest["lng"] as! CLLocationDegrees)
            let distanceInMeters = coordinate0.distance(from: coordinate1)
            if(distanceInMeters < 2000 || distanceInMeters > 500){
                self.destName += "\(dest["name"]!),"
            }
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: {
                response, error in
                guard let response = response else{
                    if error != nil{
                        print(error!)
                    }
                    return
                }
                self.setMarkers(dest: dest)
            })
        }
        return self.destName
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func setMarkers(dest: [String:Any]?){
        
        guard let dest = dest else{
            print("there is no icon")
            return
        }
        
        self.path.add(CLLocationCoordinate2D(latitude: dest["lat"] as! CLLocationDegrees, longitude: dest["lng"] as! CLLocationDegrees))
        self.path.add(CLLocationCoordinate2D(latitude: locationManager.location?.coordinate.latitude as! CLLocationDegrees, longitude: locationManager.location?.coordinate.longitude as! CLLocationDegrees))
        
        let polyline = GMSPolyline(path: self.path)
        polyline.strokeWidth = 0.7
        polyline.geodesic = true
        polyline.map = self.mapView
        
        let url = URL(string: dest["icon"] as! String)
        DispatchQueue.global(qos: .background).async {
            guard let data = try? Data(contentsOf: url!),
                let image = UIImage(data: data)
                else {
                    print("there is no image")
                    return
            }
            
            DispatchQueue.main.async {
                let location = CLLocationCoordinate2D(latitude: dest["lat"] as! CLLocationDegrees, longitude: dest["lng"] as!CLLocationDegrees)
                let marker = GMSMarker(position: location)
                marker.snippet = dest["vicinity"] as? String
                marker.title = dest["name"] as? String
                marker.icon = self.imageWithImage(image: image, scaledToSize: CGSize(width: 18.0, height: 18.0))
                marker.map = self.mapView
            }
        }
    }
    
    func requestHandler(request: URLRequest,completionHandler handler:@escaping (_ result: [[String:Any]]?,_ error: String?) -> Void){
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            func displayError(_ error: String) {
                print(error)
                handler(nil,error)
            }
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            /* 5. Parse the data */
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject])
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let destinations = parsedResult["results"] as? NSArray, destinations.count != 0   else{
                displayError("Could not parse the parsed data as : '\(String(describing: parsedResult))'")
                return
            }
            
            for dest in destinations
            {
                var dictionary: [String:Any] = [String:Any]()
                
                guard let dict = dest as? NSDictionary, let geo = dict["geometry"] as? NSDictionary, let loc = geo["location"] as? NSDictionary  else{
                    displayError("Could not parse the parsed data as : '\(String(describing: parsedResult))'")
                    return
                }
                
                guard let icon =  dict["icon"] as? String else{
                    displayError("Could not parse the icon")
                    return
                }
                
                guard let name =  dict["name"] as? String else{
                    displayError("Could not parse the name")
                    return
                }
                
                guard let vicinity =  dict["vicinity"]  as? String else{
                    displayError("Could not parse the vicinity")
                    return
                }
                
                guard let placeId = dict["place_id"] as? String else{
                    displayError("Could not parse the vicinity")
                    return
                }
                
                dictionary = ["lat" :loc["lat"] as! Double,"lng" :loc["lng"] as! Double,"icon" :icon ,"vicinity": vicinity ,"name": name, "place_id": placeId ]
                self.array.append(dictionary)
            }
            self.array = self.noDuplicates(self.array)
            handler(self.array,nil)
        }
        task.resume()
    }
    
    func noDuplicates(_ arrayOfDicts: [[String: Any]]) -> [[String: Any]] {
        var noDuplicates = [[String: Any]]()
        var usedNames = [String]()
        for dict in arrayOfDicts {
            if let name = dict["name"], !usedNames.contains(name as! String) {
                noDuplicates.append(dict)
                usedNames.append(name as! String)
            }
        }
        return noDuplicates
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    private func destinationURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Destination.APIScheme
        components.host = Constants.Destination.APIHost
        components.path = Constants.Destination.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .badge, .sound])
    }
    
    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
            self.locationManager.stopUpdatingLocation()
            self.startUpdatingLocation()
            self.path.removeAllCoordinates()
            let polyline = GMSPolyline(path: self.path)
            polyline.map = nil
            self.array = []
            self.placeConfiguration()
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            placeConfiguration()
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

