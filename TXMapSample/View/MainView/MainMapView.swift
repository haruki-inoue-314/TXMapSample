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
            self.control.drawRailwayLine(mapView)
        }
    }
    
    func drawRailwayLine(_ mapView: MGLMapView) {
        Task {
            let data = await loadGeoJSONData()
            
            await MainActor.run {
                drawPolyline(mapView, geoJson: data)
            }
        }
    }
    
    func loadGeoJSONData() async -> Data {
        guard let jsonURL = Bundle.main.url(forResource: "TX_Railway", withExtension: "geojson") else {
            preconditionFailure("GeoJSONファイルの読み込みに失敗しました")
        }
        
        guard let jsonData = try? Data(contentsOf: jsonURL) else {
            preconditionFailure("GeoJSONファイルのパースに失敗しました")
        }
        
        return jsonData
    }
    
    func drawPolyline(_ mapView: MGLMapView, geoJson: Data) {
        
        guard let style = mapView.style else {
            return
        }
        
        // GeoJSONデータからShapeを生成
        guard
            let shapeFromGeoJson = try? MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue)
        else {
            fatalError("MGLShapeの生成ができませんでした")
        }
        
        // 表示ソースを定義
        let soruce = MGLShapeSource(identifier: "polyline", shape: shapeFromGeoJson, options: nil)
        style.addSource(soruce)
        
        // レイヤーを定義
        let layer = MGLLineStyleLayer(identifier: "polyline", source: soruce)
        
        // 始点・終点の形
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        
        // 線の色
        layer.lineColor = NSExpression(forConstantValue: UIColor.red)
        
        // 線の幅
        layer.lineWidth = NSExpression(forConstantValue: 2.0)
        
        // Viewにレイヤーを追加
        style.addLayer(layer)
    }
    
}
