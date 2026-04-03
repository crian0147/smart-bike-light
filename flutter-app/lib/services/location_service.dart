import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

class LocationService extends ChangeNotifier {
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _locationTimer;
  
  // Getters
  bool get serviceEnabled => _serviceEnabled;
  PermissionStatus get permissionGranted => _permissionGranted;
  LocationData? get currentLocation => _currentLocation;
  
  // 初始化位置服务
  Future<void> initialize() async {
    try {
      // 检查服务是否启用
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }
      
      // 检查权限
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
      
      // 获取当前位置
      _currentLocation = await location.getLocation();
      notifyListeners();
      
    } catch (e) {
      print('位置服务初始化失败: $e');
    }
  }
  
  // 开始位置更新
  Future<void> startLocationUpdates() async {
    if (!_serviceEnabled || _permissionGranted != PermissionStatus.granted) {
      await initialize();
    }
    
    try {
      // 设置位置更新间隔
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        interval: Duration(seconds: 5),
        distanceFilter: 10,
      );
      
      // 开始监听位置变化
      _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
        _currentLocation = currentLocation;
        notifyListeners();
      });
      
      // 设置定时器定期获取位置
      _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
        try {
          LocationData locationData = await location.getLocation();
          _currentLocation = locationData;
          notifyListeners();
        } catch (e) {
          print('获取位置失败: $e');
        }
      });
      
    } catch (e) {
      print('开始位置更新失败: $e');
    }
  }
  
  // 停止位置更新
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationTimer?.cancel();
    _locationSubscription = null;
    _locationTimer = null;
  }
  
  // 获取当前位置
  Future<LocationData?> getCurrentLocation() async {
    try {
      LocationData locationData = await location.getLocation();
      _currentLocation = locationData;
      notifyListeners();
      return locationData;
    } catch (e) {
      print('获取当前位置失败: $e');
      return null;
    }
  }
  
  // 计算距离
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 地球半径（米）
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
                cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }
  
  // 保存轨迹点
  void saveTrackPoint(double latitude, double longitude) {
    // 这里应该将轨迹点保存到本地存储或云端
    print('保存轨迹点: $latitude, $longitude');
  }
  
  // 获取轨迹历史
  List<Map<String, dynamic>> getTrackHistory() {
    // 这里应该从本地存储或云端获取轨迹历史
    return [];
  }
  
  // 清理资源
  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}