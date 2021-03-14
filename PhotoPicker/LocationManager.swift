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
            print(place)
            
            var name = ""
            
            if let locality = place.locality
            {
                name += locality
                print(name)
            }
            
            if let country = place.country
            {
                name += country
                print(name)
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
