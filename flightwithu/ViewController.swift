//
//  ViewController.swift
//  flightwithu
//
//  Created by James‘ Mac on 2020/4/7.
//  Copyright © 2020 James‘ Mac. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
     //let map : MKMapView
     //let locationManager : CLLocationManager
    
    var flightDirection = CLLocationDirection()
    
    let locationManager = CLLocationManager()
    var currentLocation : CLLocation!
    var lock = NSLock()
    var regionRadius : CLLocationDistance = 30000
    var currentCoor : String = ""
    var coordinates : [CLLocationCoordinate2D] = []
    var flightNo : String = ""
    
    var prePolyline : MKPolyline!
    var coordinatorCount : NSInteger = 0
    
    var timer1 : Timer!
    var lat : Double!
    var lon : Double!
    var preAnnotation : MKPointAnnotation!
    
    var flightIconSize : NSInteger = 35
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var zoomInBtn: UIButton!
    @IBOutlet weak var zoomOutBtn: UIButton!
    
    @IBAction func searchBtnClick(_ sender: UIButton) {
        let prompt = UIAlertController(title: "航班号", message: "请输入您需要查询的航班号，然后点击查询按钮。", preferredStyle: UIAlertController.Style.alert)
        prompt.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.default, handler: nil))
        prompt.addAction(UIAlertAction(title: "查询", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            // Now do whatever you want with inputTextField (remember to unwrap the optional)
            let flightNoField = prompt.textFields![0]
            if !self.flightNo.isEmpty && self.flightNo != flightNoField.text! {
                self.timer1.invalidate()
            }
            self.flightNo = flightNoField.text!
            self.coordinates.removeAll()
            //self.nextPointIndex = 0

            self.getYourLoveCurrentPos()
            self.whereYourLove()
            
            self.timer1 = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (myTimer) in
                self.getYourLoveCurrentPos()
                self.whereYourLove()
            }
        }))
        prompt.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "航班号"
            //textField.isSecureTextEntry = true
            //self.flightNoField = textField
         })

        present(prompt, animated: true, completion: nil)
        
        
            /*
        
        if flightNoField.text!.isEmpty {
            return
        }
 */
    }
    
    /*
     map zoomout 地图缩小
     */
    @IBAction func zoomOutBtnClick(_ sender: UIButton) {
        let center : CLLocationCoordinate2D = self.mapView.region.center
        let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: self.mapView.region.span.latitudeDelta * 0.5, longitudeDelta: self.mapView.region.span.longitudeDelta * 0.5);
        self.mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        regionRadius *= 0.5
        flightIconSize -= 1
    }
    
    /*
     map zoomin 地图放大
     */
    @IBAction func zoomInBtnClick(_ sender: UIButton) {
        let center : CLLocationCoordinate2D = self.mapView.region.center
        let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: self.mapView.region.span.latitudeDelta * 2, longitudeDelta: self.mapView.region.span.longitudeDelta * 2);
        self.mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        regionRadius *= 2
        flightIconSize += 1
    }
    
    /*
     每10秒调用一次这个方法，刷新飞机目前位置。
     */
    
    func getYourLoveCurrentPos() {
        let result = query(address: "http://122.51.134.114:8080/getflight?no=" + flightNo + "&i=" + String(self.coordinates.count))
        
        if result.status == "arrived" {
            // 停止处理
            return
        }
        
        guard !result.items.isEmpty else {
            print("api return null")
            return
        }
        
        for item in result.items {
            let coordinateArr = item.components(separatedBy: ",")
            //var coordinatesToAppend : CLLocationCoordinate2D;
            if coordinateArr[0] == "null" || coordinateArr[1] == "null" {
                print("double null.")
                continue
            }
            
            lat = Double(coordinateArr[0])
            lon = Double(coordinateArr[1])
            //if !self.coordinates.contains { $0.latitude == lat && $0.longitude == lon } {
                //coordinatesToAppend = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            /*
            } else {
                print("already exist.")
            }
 */
        }
        
        /*
        let coordinateArr = coordinateStr.components(separatedBy: ",")
        var coordinatesToAppend : CLLocationCoordinate2D;
        if coordinateArr[0] == "null" || coordinateArr[1] == "null" {
            print("double null.")
            guard !self.coordinates.isEmpty else {
                return
            }
            coordinatesToAppend = CLLocationCoordinate2D(latitude: self.coordinates.last!.latitude, longitude: self.coordinates.last!.longitude)
        } else {
            coordinatesToAppend = CLLocationCoordinate2D(latitude: Double(coordinateArr[0])!, longitude: Double(coordinateArr[1])!)
        }
        self.coordinates.append(coordinatesToAppend)
 */
        
        /*
        let urlStr = "http://122.51.134.114:8080/getflight?no=" + self.flightNoField.text!
        let url = NSURL.init(string: urlStr)
        let request : NSMutableURLRequest  = NSMutableURLRequest.init(url: url! as URL)
        request.httpMethod = "POST"
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if(error == nil){
                let coordinateStr = String(data: data!, encoding: String.Encoding.utf8)!
                let coordinateArr = coordinateStr.components(separatedBy: ",")
                var coordinatesToAppend : CLLocationCoordinate2D;
                
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                        print("Your love is arrived.")
                        return
                }
                
                guard coordinateArr[0] != "null" && coordinateArr[1] != "null" else {
                    print("double null.")
                    return
                }
                
                coordinatesToAppend = CLLocationCoordinate2D(latitude: Double(coordinateArr[0])!, longitude: Double(coordinateArr[1])!)
                self.coordinates.append(coordinatesToAppend)
                
                /*
                if coordinateArr[0] == "null" || coordinateArr[1] == "null" {
                    //coordinatesToAppend = CLLocationCoordinate2D(latitude: self.coordinates.last!.latitude, longitude: self.coordinates.last!.longitude)
                } else {
                    coordinatesToAppend = CLLocationCoordinate2D(latitude: Double(coordinateArr[0])!, longitude: Double(coordinateArr[1])!)
                }
 */
                //self.coordinates.append(coordinatesToAppend)
                // print("接口返回的坐标是:\(str)")
            }
        }
        task.resume()
 */
    }
    
    func query(address: String) -> (status : String, items : [String]) {
        let url = URL(string: address)
        let semaphore = DispatchSemaphore(value: 0)
        var statusV : String = ""
        var itemsV : [String] = []
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            /*
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    return
            }
 */
            let response = response as! HTTPURLResponse
            if (200...299).contains(response.statusCode) {
                statusV = "ing" //String(data: data!, encoding: String.Encoding.utf8)!
                itemsV = self.dataParsing(data: data!) as! [String]
            } else {
                // todo 需要根据飞机海拔高度和速度都为0判断为着陆，表示已经到达
                statusV = "arrived"
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return (statusV, itemsV)
    }
    
    func dataParsing(data:Data) -> Any {
        /**
         先判断是否可以解析
         */
        return try! JSONSerialization.jsonObject(with: data as Data, options:.mutableContainers)
    }
    
    var nextPointIndex : Int = 0 {
        didSet {
            UIView.animate(
                withDuration: 10,
                animations: {
                    self.whereYourLove()
            },
                completion: { _ in
                    self.getYourLoveCurrentPos()
                    self.nextPointIndex += 1
            })
        }
    }
    
    func whereYourLove() {
        guard !coordinates.isEmpty else {
            return
        }
        if coordinatorCount == coordinates.count {
            return
        }
        createAnnotations()
        /*以下两句实现自动跟踪*/
        let centerLocation = CLLocation(latitude: coordinates.last!.latitude, longitude: coordinates.last!.longitude)
        centerMapOnLocation(location: centerLocation)
        coordinatorCount = coordinates.count
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinatorCount)
        if self.prePolyline != nil {
            /*
             注释以下这句，可以支持多航班同时跟踪
             */
            //mapView.removeOverlay(self.prePolyline)
        }
        mapView.addOverlay(polyline)
        self.prePolyline = polyline
    }
    
    var deliveryAnnotation: MKPointAnnotation = {
        let annotation = MKPointAnnotation()
        annotation.title = "your love"
        
        return annotation
    }()
    
    /*
     只要坐标集发生变化，都会触发whereYourLov1e
     */
    
    func createAnnotations() {
        // 只在最新位置显示标注点
        let annotation = MKPointAnnotation()
        annotation.title = flightNo
        annotation.coordinate = CLLocationCoordinate2D(latitude: coordinates.last!.latitude, longitude: coordinates.last!.longitude)
        mapView.addAnnotation(annotation)
        // 消除前一位置标示
        if preAnnotation != nil {
            mapView.removeAnnotation(preAnnotation)
        
            let oldLatitude : Double! = preAnnotation.coordinate.latitude
            let oldLongitude : Double! = preAnnotation.coordinate.longitude
            let latitude : Double! = annotation.coordinate.latitude
            let longitude : Double! = annotation.coordinate.longitude
            flightDirection = directionBetweenPoints(sourcePoint: MKMapPoint(CLLocationCoordinate2DMake(oldLatitude!, oldLongitude!)), destinationPoint: MKMapPoint(CLLocationCoordinate2DMake(latitude!, longitude!)))       // Get direction of flight
        }
        preAnnotation = annotation
        
        /*
        for coordinate in coordinates {
            let annotation  = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            mapView.addAnnotation(annotation)
        }
 */
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
      mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // For rotating flight annotations:
    func degreesToRadians(degrees: Double) -> Double { return degrees * Double.pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / Double.pi }
    func directionBetweenPoints(sourcePoint: MKMapPoint, destinationPoint : MKMapPoint) -> CLLocationDirection {
        let x : Double = destinationPoint.x - sourcePoint.x;
        let y : Double = destinationPoint.y - sourcePoint.y;

        return fmod(radiansToDegrees(radians: atan2(y, x)), 360.0)/* + 90.0*/;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        // Swift UIButton circle
        zoomInBtn.layer.cornerRadius = 14.0
        zoomInBtn.layer.masksToBounds = true
        zoomOutBtn.layer.cornerRadius = 14.0
        zoomOutBtn.layer.masksToBounds = true
        searchBtn.layer.cornerRadius = 6.0
        searchBtn.layer.masksToBounds = true
        
        //let initialLocation = CLLocation(latitude: 21.580590, longitude: 110.826260)
        //centerMapOnLocation(location: initialLocation)

        /*
        let map = MKMapView(frame: self.view.bounds)
        map.showsUserLocation = true
        map.mapType = MKMapType.standard
        self.mapView.addSubview(map)
        mapView.delegate = self
 */

        
        /*
        let polyLine = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        
        let region = polyLine.boundingMapRect
        
        self.mapView.setRegion(MKCoordinateRegion(region), animated: true)

        self.mapView.addOverlay(polyLine, level: MKOverlayLevel.aboveRoads)
                
        self.mapView.delegate = self
 */

        
        /*
        // 1.在ViewController实现MKMapViewDelegate协议的委托
        mapView.delegate = self
        //2.设置位置的纬度和经度
        let sourceLocation = CLLocationCoordinate2D(latitude: 40.759011, longitude: -73.984472)
        let destinationLocation = CLLocationCoordinate2D(latitude: 40.748441, longitude: -73.985564)
        // 3.创建包含位置坐标的地标对象
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        // 4.MKMapitems用于路线的绘制。 此类封装有关地图上特定点的信息
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        // 5. 添加注释，显示地标的名称
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.title = "Times Square"
        // 如果地标对象的坐标存在，就给MK点解释对象指点坐标
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "Empire State Building"
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        // 6.标记注释显示在地图上
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        // 7. MKDirectionsRequest类用于计算路线。折线
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        // 8.将使用折线作为地图顶部的叠加视图绘制路线。区域设置为两个位置都可见
        directions.calculate {
            (response, error) -> Void in

            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }

                return
            }

            let route = response.routes[0]
            print("111")
            route.polyline.title = "one"
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)

        }
        // 添加两个点直接相连的斜线
        let routeLine = MKPolyline(coordinates: [sourceLocation,destinationLocation], count: 2)
        routeLine.title = "two"
        self.mapView.addOverlay(routeLine)
        let rect1 = routeLine.boundingMapRect

        self.mapView.setRegion(MKCoordinateRegion(rect1), animated: true)
        
        
        /*
        //let locationManager = CLLocationManager.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.startUpdatingLocation()
        
        if CLLocationManager.locationServicesEnabled() == false {
            print("请确认已开启定位服务");
            return;
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
 */
 
        /*
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //定位精确度（最高）一般有电源接入，比较耗电
        //kCLLocationAccuracyNearestTenMeters;                    //精确到10米
        locationManager.distanceFilter = 50                       //设备移动后获得定位的最小距离（适合用来采集运动的定位）
        locationManager.requestWhenInUseAuthorization()           //弹出用户授权对话框，使用程序期间授权（ios8后)
        //requestAlwaysAuthorization;                             //始终授权
        locationManager.startUpdatingLocation()
        print("开始定位》》》")
 */
 */
    }
    
    /*
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lock.lock()
        currentLocation = locations.last                        //注意：获取集合中最后一个位置（最新的位置）
        print("定位经纬度为：\(currentLocation.coordinate.latitude)")
        //一直发生定位错误输出结果为0：原因是我输出的是currentLocation.altitude(表示高度的)而不是currentLoction.coordinate.latitude（这个才是纬度）
        print(currentLocation.coordinate.longitude)
        lock.unlock()
 
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("定位出错拉！！\(error)")
    }
 */

}


extension ViewController : MKMapViewDelegate {
    // 渲染overlay的函数
    /*
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //画出两条线：
        let routeLineView = MKPolylineRenderer(overlay: overlay)
          routeLineView.lineWidth = 4.0
        if overlay is MKPolyline{
            if overlay.title == "one"{
                routeLineView.strokeColor = UIColor.red
            }else
                if overlay.title == "two" {
                routeLineView.strokeColor = UIColor.green
            }
        }
            return routeLineView
    }
    
    */
    // 自定义标记的样式：
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView") ?? MKAnnotationView()
        let image = UIImage(systemName: "airplane")?.imageWithImage(scaledToSize:CGSize(width:flightIconSize,height:flightIconSize)).maskImageWithColor(color: UIColor.orange)
        annotationView.image = image

        UIView.animate(
            withDuration: 0,
            animations: {
                annotationView.transform = CGAffineTransform(rotationAngle: CGFloat(self.degreesToRadians(degrees: self.flightDirection)))
        })
        
        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // draw the track
        let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
        polyLineRenderer.strokeColor = UIColor.systemPink
        polyLineRenderer.lineWidth = 1.5
        polyLineRenderer.lineJoin = .round

        return polyLineRenderer
    }
}

//MARK: 改变图片颜色
extension UIImage{
    /// 更改图片颜色
    public func maskImageWithColor(color : UIColor) -> UIImage{
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImage!
    }
    
    func imageWithImage(scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x:0, y:0, width:newSize.width, height:newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
