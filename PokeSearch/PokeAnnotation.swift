//
//  PokeAnnotation.swift
//  PokeSearch
//
//  Created by Ievgen Keba on 11/22/16.
//  Copyright © 2016 Harman Inc. All rights reserved.
//

import UIKit
import MapKit

class PokeAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var pokemonName: String?
    var title: String?
    var pokemonNumber: Int?
    
    
    init(coordinate: CLLocationCoordinate2D, pokemonNumber: Int) {
        self.coordinate = coordinate
        self.pokemonNumber = pokemonNumber
        
        let parse = Bundle.main.path(forResource: "pokemon", ofType: "csv")
        do {
            let csv = try CSV(contentsOfURL: parse!)
            self.pokemonName = (csv.rows[pokemonNumber]["identifier"])?.capitalized
        } catch let error as NSError {
            print(error.debugDescription)
        }
        self.title = self.pokemonName
    }
}
