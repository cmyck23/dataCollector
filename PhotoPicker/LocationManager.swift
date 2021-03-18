import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate{
    static let shared = LocationManager()
    
    let manager = CLLocationManager()
    var completion: ((CLLocation)-> Void)?
    
    
    var name = ""
    var streetDetails = "None"
    var street = "None"
    var locality = "None"
    var country = "None"
    var state_Province = "None"
    var postal_Code = "None"
    
    public func getUserLocation(completion: @escaping ((CLLocation) -> Void))
    {
        self.completion = completion
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.startUpdatingLocation()
    }
    
    public func resolveLocationName(with location: CLLocation, completion: @escaping((String?)-> Void)) -> String {
    
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: .current)
            {placemarks,
             error in
            guard let place = placemarks?.first,error == nil else{
                completion(nil)
                return
            }
            
            self.name = ""
            
            self.streetDetails = place.subThoroughfare ?? "None"
            
            if self.streetDetails != "None"
            {
                self.name += self.streetDetails
                self.name += " "
            }
            
            
            self.street = place.thoroughfare ?? "None"
            
            if self.street != "None" {
                
                self.name += self.street
                self.name += " "
            }
            
            self.locality = place.locality ?? "None"
            
            if self.locality != "None"{
            self.name += self.locality
            self.name += " "
            }
            
            self.country = place.country ?? "None"
            
            if self.country != ""{
            self.name += self.country
            self.name += " "
            
            }
            
            self.state_Province = place.administrativeArea ?? "None"
            
            if self.state_Province != "None"{
            self.name += self.state_Province
            self.name += " "
            }
            
            
            self.postal_Code = place.postalCode ?? ""
            if self.postal_Code != "None"{
            self.name += self.postal_Code
            }
        
            completion(self.name)
            
        }
        
        return (self.name)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let location = locations.first else {
            return
        }
         completion?(location)
        manager.stopUpdatingLocation()
    }

}
