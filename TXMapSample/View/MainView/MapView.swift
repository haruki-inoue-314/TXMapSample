import Mapbox
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeUIView(context: Context) -> some UIView {
        let styleURL = URL(string: "https://api.maptiler.com/maps/jp-mierune-gray/style.json?key=\(APIKey.mapTilerKey)")
        
        let mapView = MGLMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        
        // TXの路線の重心を地図の中心に設定
        mapView.setCenter(
            CLLocationCoordinate2D(
                latitude: 35.894930906699322,
                longitude: 139.937432307518321
            ),
            zoomLevel: 9.2,
            animated: false
        )
        
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MGLMapViewDelegate {
        var control: MapView
        
        init(_ control: MapView) {
            self.control = control
        }
        
        func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
            self.control.drawRailwayAndStation(mapView)
        }
    }
    
    func drawRailwayAndStation(_ mapView: MGLMapView) {
        Task {
            let railwayData = await loadGeoJSONData(resourceName: "TX_Railway")
            let stationData = await loadGeoJSONData(resourceName: "TX_Station")
//            let municipalityData = await loadGeoJSONData(resourceName: "TX_Municipality")
            
            await MainActor.run {
//                drawMunicipality(mapView, geoJson: municipalityData)
                drawRailway(mapView, geoJson: railwayData)
                drawStation(mapView, geoJson: stationData)
            }
            
        }
    }
    
    func loadGeoJSONData(resourceName: String) async -> Data {
        guard let jsonURL = Bundle.main.url(forResource: resourceName, withExtension: "geojson") else {
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
        let shapeSource = MGLShapeSource(identifier: "railway-source", shape: shapeFromGeoJson, options: nil)
        style.addSource(shapeSource)
        
        // レイヤーを定義
        let lineLayer = MGLLineStyleLayer(identifier: "railway-line-style", source: shapeSource)
        
        // 始点・終点の形
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        
        // 線の色
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.orange)
        
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
        let shapeSource = MGLShapeSource(identifier: "station-source", shape: shapeFromGeoJson, options: nil)
        style.addSource(shapeSource)
        
        // 駅の場所をCircleStyleに表示
        let circleLayer = MGLCircleStyleLayer(identifier: "station-circle-style", source: shapeSource)
        circleLayer.circleColor = NSExpression(forConstantValue: UIColor.orange)
        circleLayer.circleRadius = NSExpression(
            format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
            [10: 4.0, 18: 16.0]
        )
        style.addLayer(circleLayer)
        
        // 駅名をSymbolStyleLayerで表示する
        let shapeLayer = MGLSymbolStyleLayer(identifier: "station-symbol-style", source: shapeSource)
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
    
    func drawMunicipality(_ mapView: MGLMapView, geoJson: Data) {
        guard let style = mapView.style else {
            return
        }
        
        // GeoJSONデータからShapeを生成
        guard
            let shapeFromGeoJson = try? MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue)
        else {
            fatalError("MGLShapeの生成ができませんでした")
        }
        
        // 土地利用のポリゴンをSourceとして登録して、MapViewのStyleに追加
        let shapeSource = MGLShapeSource(identifier: "municipality-source", shape: shapeFromGeoJson, options: nil)
        style.addSource(shapeSource)
        
        // 市町村ポリゴンのスタイルを定義
        let fillStyleLayer = MGLFillStyleLayer(identifier: "municipality-fill-style", source: shapeSource)

        fillStyleLayer.fillColor = NSExpression(
            format: "MGL_MATCH(N03_001, '東京都', %@, '埼玉県', %@, '千葉県', %@, '茨城県', %@, %@)",
            UIColor.red,
            UIColor.yellow,
            UIColor.green,
            UIColor.blue,
            UIColor.black
        )
        
        fillStyleLayer.fillOpacity = NSExpression(forConstantValue: 0.2)
        
        style.addLayer(fillStyleLayer)
        
        // ポリゴンの輪郭線スタイルを定義
        let lineLayer = MGLLineStyleLayer(identifier: "municipality-line-style", source: shapeSource)
        lineLayer.lineWidth = NSExpression(forConstantValue: 1.0)
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.black)
        
        style.addLayer(lineLayer)
    }
    
}
