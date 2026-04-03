/**
 * @file sensors.h
 * @brief 传感器驱动和数据处理
 */

#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_ICM20948.h>
#include <Adafruit_GPS.h>
#include <TinyGPS++.h>

// 传感器数据结构
struct SensorData {
  // IMU 数据
  float accelX, accelY, accelZ;
  float gyroX, gyroY, gyroZ;
  float heading;
  
  // 速度数据
  float speed;
  unsigned long lastPulseTime;
  
  // GPS 数据
  float latitude;
  float longitude;
  int satellites;
  
  // 雷达数据
  unsigned long radarDistance;
  bool radarMovingTarget;
  
  // 环境数据
  int lightLevel;
  float batteryVoltage;
  int batteryPercentage;
  
  // 状态
  bool isNight;
  bool theftMode;
};

class SensorManager {
public:
  SensorManager();
  bool begin();
  void update();
  
  // 获取传感器数据
  SensorData getData() { return data; }
  
  // 获取速度
  float getSpeed() { return data.speed; }
  
  // 获取电量
  int getBatteryPercentage() { return data.batteryPercentage; }
  
  // 是否夜间模式
  bool isNightMode() { return data.isNight; }
  
  // 是否防盗模式
  bool isTheftMode() { return data.theftMode; }
  
  // 设置防盗模式
  void setTheftMode(bool mode) { data.theftMode = mode; }
  
private:
  SensorData data;
  
  // IMU
  Adafruit_ICM20948 icm;
  
  // GPS
  Adafruit_GPS GPS;
  TinyGPSPlus tinyGPS;
  
  // 内部函数
  void initIMU();
  void initGPS();
  void initRadar();
  void readIMU();
  void readGPS();
  void readRadar();
  void readLightSensor();
  void readBattery();
  void calculateSpeed();
  void updateEnvironment();
};

#endif // SENSORS_H