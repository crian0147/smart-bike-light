/*
 * Smart Bike Light - ESP32-S3 Firmware
 * 智能单车尾灯 - ESP32-S3 固件
 * 
 * 功能：
 * - IMU 数据采集（ICM-20948）
 * - 霍尔传感器速度检测
 * - GPS 数据采集（ATGM336H）
 * - 微波雷达来车检测（HLK-LD2410）
 * - 光敏电阻环境光检测
 * - WS2812B LED 智能灯效
 * - BLE 通信（手机 App）
 * - 电量监测
 */

#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>
#include <WiFi.h>
#include <BluetoothSerial.h>
#include <Adafruit_ICM20948.h>
#include <Adafruit_NeoPixel.h>
#include <Adafruit_GPS.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>

// 引脚定义
#define PIN_HALL_SENSOR     4      // 霍尔传感器输入（外部中断）
#define PIN_THEFT_BUTTON    5      // 防盗按钮（低有效）
#define PIN_IMU_SDA         8      // ICM-20948 SDA
#define PIN_IMU_SCL         9      // ICM-20948 SCL
#define PIN_RADAR_RX        17     // 雷达数据接收
#define PIN_RADAR_TX        18     // 雷达数据发送
#define PIN_GPS_RX          43     // GPS 数据接收
#define PIN_GPS_TX          44     // GPS 数据发送
#define PIN_GPS_POWER       46     // GPS 电源控制
#define PIN_RADAR_POWER     47     // 雷达电源控制
#define PIN_LED_DATA        48     // WS2812B 数据线
#define PIN_LIGHT_SENSOR    1      // 光敏电阻（ADC1_CH0）
#define PIN_BATTERY_VOLTAGE 3      // 电池电压（ADC1_CH3）

// LED 配置
#define LED_COUNT          60     // LED 数量
#define LED_TYPE           NEO_GRB + NEO_KHZ800
#define BRIGHTNESS         50     // 默认亮度

// BLE 配置
#define BLE_DEVICE_NAME    "SmartBikeLight"
#define BLE_SERVICE_UUID   "0000ffe0-0000-1000-8000-00805f9b34fb"
#define BLE_CHAR_UUID      "0000ffe1-0000-1000-8000-00805f9b34fb"

// 全局变量
BluetoothSerial SerialBT;
Adafruit_ICM20948 icm;
Adafruit_NeoPixel strip(LED_COUNT, PIN_LED_DATA, LED_TYPE);
Adafruit_GPS GPS(&Serial1);
TinyGPSPlus tinyGPS;

// 状态变量
bool theftMode = false;
bool isNight = false;
float currentSpeed = 0.0;
float batteryVoltage = 0.0;
int batteryPercentage = 0;
unsigned long lastHallPulseTime = 0;
unsigned long speedCalculationTime = 0;

// 传感器数据结构
struct SensorData {
  float accelX, accelY, accelZ;
  float gyroX, gyroY, gyroZ;
  float heading;
  float speed;
  float latitude, longitude;
  int satellites;
  unsigned long radarDistance;
  bool radarMovingTarget;
  int lightLevel;
  bool theftAlert;
};

SensorData sensorData;

// 函数声明
void initIMU();
void initGPS();
void initRadar();
void initLED();
void initSensors();
void readIMU();
void readHallSensor();
void readGPS();
void readRadar();
void readLightSensor();
void readBattery();
void calculateSpeed();
void updateLED();
void updateBLE();
void handleTheftButton();
void sleepMode();
void wakeUp();

void setup() {
  Serial.begin(115200);
  Serial.println("Smart Bike Light - ESP32-S3 Firmware Starting...");
  
  // 初始化引脚
  pinMode(PIN_HALL_SENSOR, INPUT_PULLUP);
  pinMode(PIN_THEFT_BUTTON, INPUT_PULLUP);
  pinMode(PIN_GPS_POWER, OUTPUT);
  pinMode(PIN_RADAR_POWER, OUTPUT);
  
  // 初始化传感器
  initLED();
  initIMU();
  initGPS();
  initRadar();
  initSensors();
  
  // 初始化 BLE
  SerialBT.begin(BLE_DEVICE_NAME);
  
  Serial.println("Setup completed!");
}

void loop() {
  static unsigned long lastUpdate = 0;
  const unsigned long updateInterval = 50; // 20Hz 更新率
  
  if (millis() - lastUpdate >= updateInterval) {
    // 读取传感器数据
    readIMU();
    readHallSensor();
    readGPS();
    readRadar();
    readLightSensor();
    readBattery();
    calculateSpeed();
    
    // 处理防盗按钮
    handleTheftButton();
    
    // 更新 LED 灯效
    updateLED();
    
    // 更新 BLE 通信
    updateBLE();
    
    lastUpdate = millis();
  }
  
  // 处理 GPS 数据
  while (Serial1.available() > 0) {
    char c = Serial1.read();
    tinyGPS.encode(c);
  }
  
  // 检查低电量休眠
  if (batteryPercentage < 10) {
    sleepMode();
  }
}

// IMU 初始化
void initIMU() {
  Wire.begin(PIN_IMU_SDA, PIN_IMU_SCL);
  if (!icm.begin_I2C()) {
    Serial.println("Failed to initialize ICM-20948!");
    while (1);
  }
  Serial.println("ICM-20948 initialized successfully");
}

// GPS 初始化
void initGPS() {
  digitalWrite(PIN_GPS_POWER, HIGH);
  delay(100);
  Serial1.begin(9600, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);
  Serial.println("GPS initialized");
}

// 雷达初始化
void initRadar() {
  digitalWrite(PIN_RADAR_POWER, HIGH);
  delay(100);
  Serial2.begin(115200, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  Serial.println("Radar initialized");
}

// LED 初始化
void initLED() {
  strip.begin();
  strip.show();
  strip.setBrightness(BRIGHTNESS);
  Serial.println("LED initialized");
}

// 传感器初始化
void initSensors() {
  // 设置霍尔传感器中断
  attachInterrupt(digitalPinToInterrupt(PIN_HALL_SENSOR), hallInterrupt, RISING);
  
  Serial.println("All sensors initialized");
}

// IMU 数据读取
void readIMU() {
  icm.getEvent(&sensorData.accelX, &sensorData.accelY, &sensorData.accelZ, 
               &sensorData.gyroX, &sensorData.gyroY, &sensorData.gyroZ);
  
  // 计算倾角（简化版）
  sensorData.heading = atan2(sensorData.accelY, sensorData.accelZ) * 180 / M_PI;
}

// 霍尔传感器中断处理
void hallInterrupt() {
  unsigned long currentTime = micros();
  unsigned long pulseInterval = currentTime - lastHallPulseTime;
  lastHallPulseTime = currentTime;
  
  // 计算速度（简化计算）
  if (pulseInterval > 0) {
    float wheelCircumference = 2.135; // 700C 轮胎周长（米）
    float speedMs = wheelCircumference / (pulseInterval / 1000000.0);
    currentSpeed = speedMs * 3.6; // 转换为 km/h
  }
}

// GPS 数据读取
void readGPS() {
  if (tinyGPS.location.isValid()) {
    sensorData.latitude = tinyGPS.location.lat();
    sensorData.longitude = tinyGPS.location.lng();
    sensorData.satellites = tinyGPS.satellites.value();
  }
}

// 雷达数据读取
void readRadar() {
  // 简化的雷达数据处理
  // 实际需要解析 HLK-LD2410 的 UART 数据
  sensorData.radarDistance = 0; // 暂时设为0，需要实现具体解析
  sensorData.radarMovingTarget = false;
}

// 光敏传感器读取
void readLightSensor() {
  int adcValue = analogRead(PIN_LIGHT_SENSOR);
  sensorData.lightLevel = map(adcValue, 0, 4095, 100, 0); // 反转，暗环境值大
  
  // 判断是否为夜间模式
  isNight = (sensorData.lightLevel < 30);
}

// 电池电量读取
void readBattery() {
  int adcValue = analogRead(PIN_BATTERY_VOLTAGE);
  // 分压比：1:2，所以需要乘以2
  sensorData.batteryVoltage = (adcValue * 3.3 / 4095.0) * 2.0;
  
  // 估算电量百分比
  if (sensorData.batteryVoltage >= 4.2) {
    batteryPercentage = 100;
  } else if (sensorData.batteryVoltage >= 4.0) {
    batteryPercentage = 80;
  } else if (sensorData.batteryVoltage >= 3.7) {
    batteryPercentage = 50;
  } else if (sensorData.batteryVoltage >= 3.3) {
    batteryPercentage = 10;
  } else {
    batteryPercentage = 0;
  }
}

// 速度计算
void calculateSpeed() {
  // 每100ms计算一次平均速度
  if (millis() - speedCalculationTime >= 100) {
    sensorData.speed = currentSpeed;
    speedCalculationTime = millis();
    
    // 如果超过1秒没有脉冲，速度设为0
    if (millis() - lastHallPulseTime > 1000) {
      currentSpeed = 0.0;
    }
  }
}

// LED 灯效更新
void updateLED() {
  // 根据状态更新 LED 灯效
  if (theftMode) {
    // 防盗模式：闪烁红色
    uint32_t red = strip.Color(255, 0, 0);
    if (millis() % 1000 < 500) {
      strip.fill(red);
    } else {
      strip.clear();
    }
  } else if (currentSpeed > 0) {
    // 行驶模式：根据速度显示不同颜色
    if (currentSpeed < 10) {
      // 慢速：橙色
      uint32_t color = strip.Color(255, 165, 0);
      strip.fill(color);
    } else if (currentSpeed < 20) {
      // 中速：黄色
      uint32_t color = strip.Color(255, 255, 0);
      strip.fill(color);
    } else {
      // 快速：白色
      uint32_t color = strip.Color(255, 255, 255);
      strip.fill(color);
    }
  } else {
    // 停止模式：呼吸效果
    uint8_t brightness = (sin(millis() * 0.005) + 1) * 127;
    uint32_t color = strip.Color(255, 0, 0);
    strip.fill(color);
    strip.setBrightness(brightness);
  }
  
  strip.show();
}

// BLE 数据更新
void updateBLE() {
  if (SerialBT.hasClient()) {
    StaticJsonDocument<200> doc;
    
    doc["speed"] = sensorData.speed;
    doc["battery"] = batteryPercentage;
    doc["light"] = isNight;
    doc["theft"] = theftMode;
    doc["latitude"] = sensorData.latitude;
    doc["longitude"] = sensorData.longitude;
    
    String jsonString;
    serializeJson(doc, jsonString);
    SerialBT.println(jsonString);
  }
}

// 防盗按钮处理
void handleTheftButton() {
  static unsigned long buttonPressTime = 0;
  static bool buttonPressed = false;
  
  if (digitalRead(PIN_THEFT_BUTTON) == LOW) {
    if (!buttonPressed) {
      buttonPressed = true;
      buttonPressTime = millis();
    }
    
    // 长按5秒解除防盗模式
    if (millis() - buttonPressTime > 5000) {
      theftMode = false;
      buttonPressed = false;
    }
  } else {
    buttonPressed = false;
  }
}

// 休眠模式
void sleepMode() {
  Serial.println("Entering sleep mode...");
  digitalWrite(PIN_GPS_POWER, LOW);
  digitalWrite(PIN_RADAR_POWER, LOW);
  strip.clear();
  strip.show();
  
  // 深度休眠
  esp_sleep_enable_ext0_wakeup(GPIO_NUM_5, LOW); // 防盗按钮唤醒
  esp_deep_sleep_start();
}

// 唤醒
void wakeUp() {
  Serial.println("Waking up from sleep...");
  initSensors();
}