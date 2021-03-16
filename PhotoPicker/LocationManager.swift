import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate{
    static let shared = LocationManager()
    
    let manager = CLLocationManager()
    var completion: ((CLLocation)-> Void)?
    
    var streetDetails : String = ""
    var name = ""
    var street = ""
    var locality = ""
    var country = ""
    var state_Province = ""
    var postal_Code = ""
    
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
        
            self.streetDetails = place.subThoroughfare ?? ""
            
            self.name += self.streetDetails
            self.name += "_"
            
            
            self.street = place.thoroughfare ?? ""
            
            self.name += self.street
            self.name += "_"
            
            
            self.locality = place.locality ?? ""
            
            self.name += self.locality
            self.name += "_"
            
            
            self.country = place.country ?? ""
            
            self.name += self.country
            self.name += "_"
            
            
            self.state_Province = place.administrativeArea ?? ""
            
            self.name += self.state_Province
            self.name += "_"
            
            
            
            self.postal_Code = place.postalCode ?? ""
            self.name += self.postal_Code
            
        
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
