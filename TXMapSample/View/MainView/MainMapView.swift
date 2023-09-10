import Mapbox
import MapKit
import SwiftUI

struct MainMapView: UIViewRepresentable {
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeUIView(context: Context) -> some UIView {
        let styleURL = URL(string: "https://api.maptiler.com/maps/streets-v2/style.json?key=\(mapTilerAPIKey)")
        
        let mapView = MGLMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        mapView.setCenter(CLLocationCoordinate2D(latitude: 35.893056, longitude: 139.952417), zoomLevel: 10, animated: false)
        
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func makeCoordinator() -> MainMapView.Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MGLMapViewDelegate {
        var control: MainMapView
        
        init(_ control: MainMapView) {
            self.control = control
        }
        
        func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
            
        }
    }
    
}
