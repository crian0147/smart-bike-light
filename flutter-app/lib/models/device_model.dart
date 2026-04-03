import 'package:flutter/material.dart';

class DeviceModel extends ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  String _deviceName = '';
  String _deviceAddress = '';
  
  // 设备状态
  double _batteryLevel = 0.0;
  bool _isCharging = false;
  bool _theftMode = false;
  
  // 传感器数据
  double _speed = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  int _satellites = 0;
  bool _isNightMode = false;
  
  // LED 状态
  String _currentMode = '常亮';
  int _brightness = 50;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get deviceName => _deviceName;
  String get deviceAddress => _deviceAddress;
  
  double get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  bool get theftMode => _theftMode;
  
  double get speed => _speed;
  double get latitude => _latitude;
  double get longitude => _longitude;
  int get satellites => _satellites;
  bool get isNightMode => _isNightMode;
  
  String get currentMode => _currentMode;
  int get brightness => _brightness;
  
  // Setters
  void setConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }
  
  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }
  
  void setDeviceInfo(String name, String address) {
    _deviceName = name;
    _deviceAddress = address;
    notifyListeners();
  }
  
  void setBatteryLevel(double level) {
    _batteryLevel = level;
    notifyListeners();
  }
  
  void setCharging(bool charging) {
    _isCharging = charging;
    notifyListeners();
  }
  
  void setTheftMode(bool mode) {
    _theftMode = mode;
    notifyListeners();
  }
  
  void updateSensorData({
    double speed = 0.0,
    double latitude = 0.0,
    double longitude = 0.0,
    int satellites = 0,
    bool isNightMode = false,
  }) {
    _speed = speed;
    _latitude = latitude;
    _longitude = longitude;
    _satellites = satellites;
    _isNightMode = isNightMode;
    notifyListeners();
  }
  
  void setLightMode(String mode) {
    _currentMode = mode;
    notifyListeners();
  }
  
  void setBrightness(int brightness) {
    _brightness = brightness;
    notifyListeners();
  }
  
  // 控制方法
  void connect() {
    setConnecting(true);
    // 这里应该实现实际的蓝牙连接逻辑
    Future.delayed(const Duration(seconds: 2), () {
      setConnected(true);
      setConnecting(false);
      setDeviceInfo('Smart Bike Light', '00:11:22:33:44:55');
    });
  }
  
  void disconnect() {
    setConnected(false);
    setDeviceInfo('', '');
  }
  
  void toggleTheftMode() {
    setTheftMode(!_theftMode);
  }
  
  void setLightModeAndBrightness(String mode, int brightness) {
    setLightMode(mode);
    setBrightness(brightness);
  }
}