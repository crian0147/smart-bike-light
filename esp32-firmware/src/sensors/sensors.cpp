/**
 * @file sensors.cpp
 * @brief 传感器驱动实现
 */

#include "sensors.h"
#include <Arduino.h>

// 引脚定义
#define PIN_IMU_SDA         8
#define PIN_IMU_SCL         9
#define PIN_GPS_RX          43
#define PIN_GPS_TX          44
#define PIN_GPS_POWER       46
#define PIN_RADAR_POWER     47
#define PIN_LIGHT_SENSOR    1
#define PIN_BATTERY_VOLTAGE 3

// 轮胎周长（米）- 700C 轮胎
#define WHEEL_CIRCUMFERENCE 2.135

SensorManager::SensorManager() {
  // 初始化数据
  memset(&data, 0, sizeof(data));
}

bool SensorManager::begin() {
  // 初始化引脚
  pinMode(PIN_GPS_POWER, OUTPUT);
  pinMode(PIN_RADAR_POWER, OUTPUT);
  
  // 初始化传感器
  initIMU();
  initGPS();
  initRadar();
  
  Serial.println("Sensors initialized successfully");
  return true;
}

void SensorManager::initIMU() {
  Wire.begin(PIN_IMU_SDA, PIN_IMU_SCL);
  if (!icm.begin_I2C()) {
    Serial.println("Failed to initialize ICM-20948!");
    while (1);
  }
  Serial.println("ICM-20948 initialized");
}

void SensorManager::initGPS() {
  digitalWrite(PIN_GPS_POWER, HIGH);
  delay(100);
  
  // 使用 UART1 连接 GPS
  Serial1.begin(9600, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);
  Serial.println("GPS initialized");
}

void SensorManager::initRadar() {
  digitalWrite(PIN_RADAR_POWER, HIGH);
  delay(100);
  // 雷达初始化，这里简化处理
  Serial.println("Radar initialized");
}

void SensorManager::update() {
  // 读取各个传感器
  readIMU();
  readGPS();
  readRadar();
  readLightSensor();
  readBattery();
  calculateSpeed();
  updateEnvironment();
}

void SensorManager::readIMU() {
  icm.getEvent(&data.accelX, &data.accelY, &data.accelZ, 
               &data.gyroX, &data.gyroY, &data.gyroZ);
  
  // 计算倾角
  data.heading = atan2(data.accelY, data.accelZ) * 180 / M_PI;
}

void SensorManager::readGPS() {
  // 读取 GPS 数据
  while (Serial1.available() > 0) {
    char c = Serial1.read();
    tinyGPS.encode(c);
  }
  
  if (tinyGPS.location.isValid()) {
    data.latitude = tinyGPS.location.lat();
    data.longitude = tinyGPS.location.lng();
    data.satellites = tinyGPS.satellites.value();
  }
}

void SensorManager::readRadar() {
  // 简化的雷达数据处理
  // 实际需要解析 HLK-LD2410 的 UART 数据
  data.radarDistance = 0;
  data.radarMovingTarget = false;
  
  // 这里应该实现雷达数据的解析逻辑
  // 示例：检查是否有物体接近
  if (data.radarDistance > 0 && data.radarDistance < 500) { // 50cm 内有物体
    data.radarMovingTarget = true;
  }
}

void SensorManager::readLightSensor() {
  int adcValue = analogRead(PIN_LIGHT_SENSOR);
  // 反转数值，暗环境值大
  data.lightLevel = map(adcValue, 0, 4095, 100, 0);
  
  // 判断是否为夜间模式
  data.isNight = (data.lightLevel < 30);
}

void SensorManager::readBattery() {
  int adcValue = analogRead(PIN_BATTERY_VOLTAGE);
  // 分压比 1:2，所以需要乘以2
  data.batteryVoltage = (adcValue * 3.3 / 4095.0) * 2.0;
  
  // 估算电量百分比
  if (data.batteryVoltage >= 4.2) {
    data.batteryPercentage = 100;
  } else if (data.batteryVoltage >= 4.0) {
    data.batteryPercentage = 80;
  } else if (data.batteryVoltage >= 3.7) {
    data.batteryPercentage = 50;
  } else if (data.batteryVoltage >= 3.3) {
    data.batteryPercentage = 10;
  } else {
    data.batteryPercentage = 0;
  }
}

void SensorManager::calculateSpeed() {
  // 霍尔传感器中断处理在 main.cpp 中实现
  // 这里更新速度数据
  data.speed = getSpeed(); // 从全局变量获取
}

void SensorManager::updateEnvironment() {
  // 更新环境相关的数据
  // 可以在这里添加更多环境相关的逻辑
}