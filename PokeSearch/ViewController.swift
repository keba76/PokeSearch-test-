//
//  ViewController.swift
//  PokeSearch
//
//  Created by Ievgen Keba on 11/22/16.
//  Copyright © 2016 Harman Inc. All rights reserved.
//

import UIKit
import MapKit
import GeoFire
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    var mapHasCenteredOnce = false
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !mapHasCenteredOnce {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
            mapView.setRegion(coordinateRegion, animated: true)
            mapHasCenteredOnce = true
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annoIdentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "Ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for:.normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingOnMap(location: loc)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon sighting"
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, 1000, 1000)
            let option = [MKLaunchOptionsMapCenterKey : NSValue(mkCoordinate:regionSpan.center),
                          MKLaunchOptionsMapSpanKey : NSValue(mkCoordinateSpan:regionSpan.span),
                          MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving
                ] as [String : Any]
            MKMapItem.openMaps(with: [destination], launchOptions: option)
        }
    }
    
    func creatSighting(forLocation location: CLLocation, withPokemon pokeID: Int) {
        geoFire.setLocation(location, forKey: "\(pokeID)")
    }
    
    func showSightingOnMap(location: CLLocation) {
        
        let circleQuery = geoFire.query(at: location, withRadius: 2.5)
        _ = circleQuery?.observe(.keyEntered, with: { (key, location) in
            if let keyA = key, let locationA = location {
                let anno = PokeAnnotation(coordinate: locationA.coordinate, pokemonNumber: Int(keyA)!)
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    @IBAction func spotRandomPoke(_ sender: Any) {
        let loc = CLLocation(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1
        creatSighting(forLocation: loc, withPokemon: Int(rand))
    }    
}

