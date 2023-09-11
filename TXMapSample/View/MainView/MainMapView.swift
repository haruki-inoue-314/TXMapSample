import Mapbox
import MapKit
import SwiftUI

struct MainMapView: UIViewRepresentable {
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeUIView(context: Context) -> some UIView {
        let styleURL = URL(string: "https://api.maptiler.com/maps/jp-mierune-dark/style.json?key=\(mapTilerAPIKey)")
        
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
            self.control.drawRailwayAndStation(mapView)
        }
    }
    
    func drawRailwayAndStation(_ mapView: MGLMapView) {
        Task {
            let railwayData = await loadGeoJSONData(resouceName: "TX_Railway")
            let stationData = await loadGeoJSONData(resouceName: "TX_Station")
            
            await MainActor.run {
                drawRailway(mapView, geoJson: railwayData)
                drawStation(mapView, geoJson: stationData)
            }
            
        }
    }
    
    func loadGeoJSONData(resouceName: String) async -> Data {
        guard let jsonURL = Bundle.main.url(forResource: resouceName, withExtension: "geojson") else {
            preconditionFailure("GeoJSONファイルの読み込みに失敗しました")
        }
        
        guard let jsonData = try? Data(contentsOf: jsonURL) else {
            preconditionFailure("GeoJSONファイルのパースに失敗しました")
        }
        
        return jsonData
    }
    
    func drawRailway(_ mapView: MGLMapView, geoJson: Data) {
        
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
        let shapeSoruce = MGLShapeSource(identifier: "railway-source", shape: shapeFromGeoJson, options: nil)
        style.addSource(shapeSoruce)
        
        // レイヤーを定義
        let lineLayer = MGLLineStyleLayer(identifier: "railway-line-style", source: shapeSoruce)
        
        // 始点・終点の形
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        
        // 線の色
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.cyan)
        
//        // 線の幅（固定値）
//        lineLayer.lineWidth = NSExpression(forConstantValue: 2.0)
        
        // 線の幅
        // ズームレベルに応じて幅を変えたい場合 mgl_interpolate:withCurveType:parameters:stops: を使って定義します
        lineLayer.lineWidth = NSExpression(
            format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
            [10: 2.0, 18: 8.0]
        )
        
        // Viewにレイヤーを追加
        style.addLayer(lineLayer)
    }
    
    func drawStation(_ mapView: MGLMapView, geoJson: Data) {
        
        guard let style = mapView.style else {
            return
        }
        
        // GeoJSONデータからShapeを生成
        guard
            let shapeFromGeoJson = try? MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue)
        else {
            fatalError("MGLShapeの生成ができませんでした")
        }

        // 駅の点をSourceとして登録して、MapViewのStyleに追加
        let shapeSoruce = MGLShapeSource(identifier: "station-source", shape: shapeFromGeoJson, options: nil)
        style.addSource(shapeSoruce)
        
        // 駅の場所をCircleStyleに表示
        let circleLayer = MGLCircleStyleLayer(identifier: "station-circle-style", source: shapeSoruce)
        circleLayer.circleColor = NSExpression(forConstantValue: UIColor.cyan)
        circleLayer.circleRadius = NSExpression(
            format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
            [10: 4.0, 18: 16.0]
        )
        style.addLayer(circleLayer)
        
        // 駅名をSymbolStyleLayerで表示する
        let shapeLayer = MGLSymbolStyleLayer(identifier: "station-symbol-style", source: shapeSoruce)
        shapeLayer.text = NSExpression(forKeyPath: "N05_011")
        shapeLayer.textColor = NSExpression(forConstantValue: UIColor.white)
        shapeLayer.textTranslation = NSExpression(forConstantValue: NSValue(cgVector: CGVector(dx: -4, dy: -4)))
        shapeLayer.textFontNames = NSExpression(forConstantValue: ["HiraginoSans-W6"])
        shapeLayer.textFontSize = NSExpression(forConstantValue: 12.0)
        shapeLayer.textIgnoresPlacement = NSExpression(forConstantValue: true)
        shapeLayer.textJustification = NSExpression(forConstantValue: "right")
        shapeLayer.textAnchor = NSExpression(forConstantValue: "bottom-right")
        shapeLayer.textHaloColor = NSExpression(forConstantValue: UIColor.black)
        shapeLayer.textHaloWidth = NSExpression(forConstantValue: 1.0)

        style.addLayer(shapeLayer)
    }
    
}
