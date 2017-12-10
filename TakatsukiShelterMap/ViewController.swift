//
//  ViewController.swift
//  TakatsukiShelterMap
//
//  Created by 仲西 渉 on 2016/10/14.
//  Copyright © 2016年 nwatabou. All rights reserved.
//

import UIKit
import GoogleMaps


class ViewController: UIViewController, XMLParserDelegate, CLLocationManagerDelegate {
    
    var googleMap: GMSMapView!
    
    var latitude:CLLocationDegrees = 34.851641
    var longitude:CLLocationDegrees = 135.617857
    
    var locationManager: CLLocationManager!
    
    var parseKey:String = ""
    
    
    var lat: Double = 0.0
    var long: Double = 0.0
    
    // ズームレベル.
    let zoom: Float = 15
    
    let fileName = "takatsuki_city_Shelter"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var fileData: [[String]] = []
        
        //読み込むファイル指定
        if let csvPath = Bundle.main.path(forResource: fileName, ofType: "csv") {
            var csvString=""
            do{
                csvString = try NSString(contentsOfFile: csvPath, encoding: String.Encoding.utf16.rawValue) as String
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            csvString.enumerateLines {
                (line, stop) -> () in
                fileData.append(line.components(separatedBy: ","))
            }
        }
        
        //LocationManagerの生成
        locationManager = CLLocationManager()
        
        //Delegateの設定
        locationManager.delegate = self
        
        //距離のフィルタ
        locationManager.distanceFilter = 100.0
        
        //精度
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        //セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        //まだ認証が得られていない場合は認証ダイアログを表示
        if(status == CLAuthorizationStatus.notDetermined){
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        //位置情報の更新を開始
        locationManager.startUpdatingLocation()
        
        
        // カメラを生成.
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: latitude,longitude: longitude, zoom: zoom)
        
        let mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        
        // MapViewを生成.
        googleMap = GMSMapView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
        
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        
        googleMap.settings.myLocationButton = true
        googleMap.isUserInteractionEnabled = true
        googleMap.isMyLocationEnabled = true
        
        // MapViewにカメラを追加.
        googleMap.camera = camera
        
        loadxml()
        
        //マーカーの作成
        for i in 0 ..< fileData.count{
            let lat:CLLocationDegrees = atof(fileData[i][8])
            let long:CLLocationDegrees = atof(fileData[i][9])
            
            
            let marker: GMSMarker = GMSMarker()
            marker.position = CLLocationCoordinate2DMake(lat, long)
            marker.map = googleMap
            marker.title = fileData[i][0]
            marker.snippet = fileData[i][1]
            marker.map = googleMap
            
            //viewにMapViewを追加.
            self.view.addSubview(googleMap)
        }
        
        
        
    }
    
    func startLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        longitude = newLocation.coordinate.longitude
        latitude = newLocation.coordinate.latitude
        
        let now:GMSCameraPosition = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: zoom)
        
        googleMap.camera = now
        
        self.view.addSubview(googleMap)
    }
    
    
    func loadxml(){
        let url_text = "https://dl.dropboxusercontent.com/s/yaig0byozwjgfh6/Takatsuki_flood_map.kml?dl=0s"
        
        guard let url = NSURL(string: url_text) else{
            return
        }
        
        guard let parser = XMLParser(contentsOf: url as URL) else{
            return
        }
        
        parser.delegate = self
        parser.parse()
    }
    
    //解析の初めに呼ばれる
    func parserDidStartDocument(_ parser: XMLParser) {
        print("解析開始")
    }
    
    //タグ開始時に呼ばれる
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if(elementName == "coordinates"){
            parseKey = elementName
        }else{
            parseKey = ""
        }
    }
    
    //タグの中に要素がある場合に呼ばれる
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let rect = GMSMutablePath()
        
        if(parseKey == "coordinates"){
            let separators = NSCharacterSet(charactersIn: " ,")
            let position = string.components(separatedBy: separators as CharacterSet)
            
            if(position[0] != "\n") {
                for i in 0 ..< position.count {
                    if(i % 2 == 1){
                        lat = Double(position[i])!
                        rect.add(CLLocationCoordinate2DMake(lat,long))
                    }else{
                        long = Double(position[i])!
                    }
                }
            }
            /*
             座標の差が最大　＝　端
             その中に入っているなら描画
             */
            
            let polygon = GMSPolygon(path: rect)
            
            polygon.fillColor = UIColor(red:0.25, green:0, blue:0, alpha:0.05);
            polygon.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            polygon.fillColor = UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 0.3)
            
            polygon.strokeWidth = 2
            polygon.map = googleMap
        }
    }
    
    //閉じタグの際に呼ばれる
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    
    //解析の終わりに呼ばれる
    func parserDidEndDocument(_ parser: XMLParser) {
        print("解析終了")
    }
    
    
    func parser(_ parser: XMLParser, parseErrorOccurred parserError: Error){
        print("エラー：" + parserError.localizedDescription)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
