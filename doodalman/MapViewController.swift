//
//  TestMapViewController.swift
//  doodalman
//
//  Created by mac on 2017. 2. 13..
//  Copyright © 2017년 song. All rights reserved.
//

import UIKit
import MapKit
import GooglePlaces
import GoogleMaps

protocol MapViewDelegate {
    func roomLoaded()
}


class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, FilterViewDelegate {

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var gpsButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var delegate: MapViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.mapView.delegate = self
        self.initMap()
        self.gpsButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
        self.gpsButton.setTitle(String.fontAwesomeIcon(name: .locationArrow), for: .normal)
    }
    
    func initMap() {
        // default location
        let center = CLLocationCoordinate2D(latitude: 37.497395, longitude: 127.02933)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        self.mapView.setRegion(region, animated: false)
        self.mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.locationManager.stopUpdatingLocation()
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("moved!")
        self.fetchRoomData()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let room = view.annotation as? Room {
            performSegue(withIdentifier: "showRoom", sender: room)
        }
    }

    func fetchRoomData() {
        let centerLat = self.mapView.region.center.latitude
        let centerLon = self.mapView.region.center.longitude
        let spanLat = self.mapView.region.span.latitudeDelta
        let spanLon = self.mapView.region.span.longitudeDelta
        
        let parameters = ["centerLat": centerLat, "centerLon": centerLon, "spanLat": spanLat, "spanLon": spanLon]
        
        let model = DooDalMan.shared
        
        model.fetchRooms(parameters as [String : AnyObject]) { roomList, error in
            performUIUpdatesOnMain {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(model.filterdRooms)
                self.delegate?.roomLoaded()
            }
        }
    }
    
    func filterSaved() {
        let model = DooDalMan.shared
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(model.filterdRooms)
    }
    
    @IBAction func getUserLocation(_ sender: UIButton) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
    }
    
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRoom" {
            let roomVC = segue.destination as! RoomViewController
            roomVC.room = sender as! Room!
        }
    }


    


}


extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place coordinate: \(place.coordinate)")
        dismiss(animated: true, completion: nil)
        
        let center = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
