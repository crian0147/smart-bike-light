import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  Timer? _connectionTimer;
  
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  String _statusMessage = '未连接';
  
  // Getters
  BluetoothDevice? get device => _device;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  String get statusMessage => _statusMessage;
  
  // 初始化蓝牙
  Future<void> initialize() async {
    try {
      // 检查蓝牙是否可用
      if (!await FlutterBluePlus.isAvailable) {
        _statusMessage = '蓝牙不可用';
        notifyListeners();
        return;
      }
      
      // 检查蓝牙是否已开启
      if (!await FlutterBluePlus.isOn) {
        _statusMessage = '蓝牙未开启';
        notifyListeners();
        return;
      }
      
      _statusMessage = '准备就绪';
      notifyListeners();
    } catch (e) {
      _statusMessage = '初始化失败: $e';
      notifyListeners();
    }
  }
  
  // 开始扫描设备
  Future<void> startScan() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _scanResults.clear();
    _statusMessage = '扫描中...';
    notifyListeners();
    
    try {
      // 设置扫描回调
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // 监听扫描结果
      FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });
      
      // 10秒后停止扫描
      await Future.delayed(const Duration(seconds: 10));
      stopScan();
      
      if (_scanResults.isEmpty) {
        _statusMessage = '未找到设备';
      }
    } catch (e) {
      _statusMessage = '扫描失败: $e';
    }
    
    _isScanning = false;
    notifyListeners();
  }
  
  // 停止扫描
  void stopScan() {
    if (!_isScanning) return;
    
    FlutterBluePlus.stopScan();
    _isScanning = false;
    _statusMessage = '扫描已停止';
    notifyListeners();
  }
  
  // 连接设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    _device = device;
    _statusMessage = '连接中...';
    notifyListeners();
    
    try {
      // 设置连接状态监听
      _deviceStateSubscription = device.state.listen((state) {
        switch (state) {
          case BluetoothDeviceState.connected:
            _statusMessage = '已连接';
            _discoverServices();
            break;
          case BluetoothDeviceState.disconnecting:
            _statusMessage = '断开连接中...';
            break;
          case BluetoothDeviceState.disconnected:
            _statusMessage = '已断开连接';
            _device = null;
            _dataCharacteristic = null;
            break;
          case BluetoothDeviceState.connecting:
            _statusMessage = '连接中...';
            break;
        }
        notifyListeners();
      });
      
      // 连接设备
      await device.connect();
      
      // 设置连接超时
      _connectionTimer = Timer(const Duration(seconds: 30), () {
        if (device.state != BluetoothDeviceState.connected) {
          disconnect();
        }
      });
      
    } catch (e) {
      _statusMessage = '连接失败: $e';
      notifyListeners();
    }
  }
  
  // 断开连接
  Future<void> disconnect() async {
    try {
      _connectionTimer?.cancel();
      
      if (_device != null) {
        await _device!.disconnect();
      }
      
      _deviceStateSubscription?.cancel();
      _dataSubscription?.cancel();
      
    } catch (e) {
      _statusMessage = '断开连接失败: $e';
    }
    
    _device = null;
    _dataCharacteristic = null;
    _statusMessage = '已断开连接';
    notifyListeners();
  }
  
  // 发现服务
  Future<void> _discoverServices() async {
    if (_device == null) return;
    
    try {
      List<BluetoothService> services = await _device!.discoverServices();
      
      // 查找数据服务
      for (var service in services) {
        if (service.uuid.toString().toLowerCase().contains('ffe0')) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase().contains('ffe1')) {
              _dataCharacteristic = characteristic;
              _setupDataListener();
              break;
            }
          }
        }
      }
      
      if (_dataCharacteristic == null) {
        _statusMessage = '未找到数据特征';
      }
      
    } catch (e) {
      _statusMessage = '服务发现失败: $e';
    }
    
    notifyListeners();
  }
  
  // 设置数据监听
  void _setupDataListener() {
    if (_dataCharacteristic == null) return;
    
    _dataSubscription = _dataCharacteristic!.value.listen((value) {
      _handleData(value);
    });
  }
  
  // 处理接收到的数据
  void _handleData(List<int> data) {
    try {
      // 解析数据（JSON格式）
      String jsonString = String.fromCharCodes(data);
      print('接收到数据: $jsonString');
      
      // 这里应该解析JSON并更新设备模型
      // 例如：更新电量、速度、位置等
      
    } catch (e) {
      print('数据处理失败: $e');
    }
  }
  
  // 发送数据到设备
  Future<void> sendData(List<int> data) async {
    if (_dataCharacteristic == null || _device == null) {
      _statusMessage = '未连接到设备';
      notifyListeners();
      return;
    }
    
    try {
      await _dataCharacteristic!.write(data);
    } catch (e) {
      _statusMessage = '发送失败: $e';
      notifyListeners();
    }
  }
  
  // 发送命令到设备
  Future<void> sendCommand(String command) async {
    // 构建JSON命令
    Map<String, dynamic> commandMap = {
      'command': command,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    String jsonString = jsonEncode(commandMap);
    List<int> data = utf8.encode(jsonString);
    
    await sendData(data);
  }
  
  // 清理资源
  @override
  void dispose() {
    _deviceStateSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }
}