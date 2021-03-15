import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate{
    static let shared = LocationManager()
    
    let manager = CLLocationManager()
    var completion: ((CLLocation)-> Void)?
    
    public func getUserLocation(completion: @escaping ((CLLocation) -> Void))
    {
        self.completion = completion
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.startUpdatingLocation()
    }
    
    public func resolveLocationName(with location: CLLocation, completion: @escaping((String?)-> Void)){
    let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: .current)
            {placemarks,
             error in
            guard let place = placemarks?.first,error == nil else{
                completion(nil)
                return
            }
            
            var name = ""
            
            
            if let streetDetails = place.subThoroughfare
            {
                name += streetDetails
                name += " "
            }
            
            if let street = place.thoroughfare
            {
                name += street
                name += " "
            }
            
            if let locality = place.locality
            {
                name += locality
                name += " "
            }
            
            if let country = place.country
            {
                name += country
                name += " "
            }
            
            if let state_Province = place.administrativeArea
            {
                name += state_Province
                name += " "
            }
            
            
            if let postal_Code = place.postalCode
            {
                name += postal_Code
            }
        
            completion(name)
        }
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
