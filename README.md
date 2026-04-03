# 智能单车尾灯项目

这是一个基于 ESP32-S3 的智能单车尾灯项目，具有多种传感器和智能灯效。

## 项目结构

```
smart-bike-light/
├── PLAN.md                    # 项目计划文档
├── HARDWARE_SCHEMATIC.md      # 硬件原理图
├── HARDWARE_PCB.md           # PCB 设计文档
├── esp32-firmware/           # ESP32 固件
│   ├── platformio.ini        # PlatformIO 配置
│   ├── src/
│   │   ├── main.cpp          # 主程序
│   │   ├── sensors/
│   │   │   ├── sensors.h    # 传感器头文件
│   │   │   └── sensors.cpp   # 传感器实现
│   │   └── utils/
│   │       └── led_controller.h  # LED 控制器
│   └── data/                 # 数据文件
└── flutter-app/              # Flutter 手机应用
    ├── pubspec.yaml          # 项目配置
    ├── lib/
    │   ├── main.dart         # 主程序
    │   ├── screens/
    │   │   └── home_screen.dart  # 主界面
    │   ├── widgets/
    │   │   └── animated_bottom_navigation_bar.dart  # 底部导航
    │   ├── models/
    │   │   └── device_model.dart  # 设备模型
    │   └── services/
    │       ├── bluetooth_service.dart  # 蓝牙服务
    │       └── location_service.dart    # 位置服务
    └── assets/               # 资源文件
```

## 功能特性

### 硬件功能
- **ESP32-S3 主控**：高性能双核处理器
- **IMU 传感器**：检测车身倾角和运动状态
- **霍尔传感器**：检测车轮转速，计算速度
- **GPS 模块**：定位和轨迹记录
- **微波雷达**：检测后方来车
- **光敏电阻**：环境光检测，自动调节亮度
- **WS2812B LED**：60颗 RGB LED，支持多种灯效
- **蓝牙 5.0**：与手机 App 通信

### 智能灯效
- **速度感应**：根据速度自动调整颜色
- **刹车灯效**：刹车时闪烁红色
- **转向灯效**：左右转向指示
- **来车提醒**：检测到后方来车时闪烁
- **防盗模式**：车辆被盗时报警
- **自动亮度**：根据环境光自动调节

### 手机 App 功能
- **实时监控**：显示速度、电量、位置等信息
- **灯效控制**：手动切换灯效模式
- **轨迹记录**：GPS 轨迹记录和显示
- **设置界面**：蓝牙连接、亮度调节等设置

## 硬件配置

### 主要组件
| 组件 | 型号 | 数量 | 价格 |
|------|------|------|------|
| ESP32-S3 | ESP32-S3-WROOM-1 N8R8 | 1 | ¥15 |
| IMU | ICM-20948 | 1 | ¥20 |
| 霍尔传感器 | A3144 + 钕铁硼磁铁 | 1套 | ¥5 |
| LED 灯带 | WS2812B 144LED/m | 0.5m | ¥8 |
| 微波雷达 | HLK-LD2410B | 1 | ¥20 |
| GPS | ATGM336H-5N | 1 | ¥15 |
| 光敏电阻 | GL5528 | 1 | ¥1 |
| 电池 | 18650 3000mAh | 2 | ¥20 |
| 充电模块 | TP4056 Type-C | 2 | ¥6 |
| 稳压模块 | AMS1117-3.3 | 1 | ¥2 |
| 升压模块 | MT3608 | 1 | ¥2 |
| 三极管 | S8050 | 2 | ¥1 |
| 其他 | 电容、电阻、按钮等 | 若干 | ¥3 |

### 总成本：约 ¥110

## 开发进度

### ✅ 已完成
- [x] 项目规划和文档
- [x] 硬件原理图设计
- [x] PCB 设计文档
- [x] ESP32 固件框架搭建
- [x] 传感器驱动实现
- [x] LED 控制器实现
- [x] Flutter App 框架搭建
- [x] 蓝牙通信服务
- [x] 位置服务实现
- [x] 主界面设计

### 🔄 开发中
- [ ] ESP32 固件功能完善
- [ ] 雷达数据解析
- [ ] LED 灯效实现
- [ ] 手机 App 功能完善
- [ ] 轨迹记录功能
- [ ] 数据同步功能

### ⏳ 待开发
- [ ] 硬件原型制作
- [ ] PCB 打样和焊接
- [ ] 外壳 3D 打印
- [ ] 实地测试
- [ ] 性能优化
- [ ] 用户手册

## 技术栈

### 硬件
- **开发平台**：ESP32-S3 DevKitC-1
- **编程语言**：C++ (Arduino)
- **开发工具**：PlatformIO
- **通信协议**：I²C, UART, SPI, BLE

### 软件
- **移动端**：Flutter (Dart)
- **平台**：iOS, Android
- **地图服务**：Google Maps
- **状态管理**：Provider
- **蓝牙通信**：Flutter Blue Plus

## 使用说明

### 硬件连接
1. 按照 `HARDWARE_SCHEMATIC.md` 连接所有组件
2. 确保电源供应稳定
3. 检查传感器安装位置

### 固件烧录
1. 安装 PlatformIO
2. 打开 `esp32-firmware` 目录
3. 运行 `pio run -t upload` 烧录固件

### 手机 App 使用
1. 安装 Flutter SDK
2. 运行 `flutter pub get` 安装依赖
3. 运行 `flutter run` 启动应用
4. 通过蓝牙连接设备

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License