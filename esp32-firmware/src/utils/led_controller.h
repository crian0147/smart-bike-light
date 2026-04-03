/**
 * @file led_controller.h
 * @brief LED 灯效控制器
 */

#ifndef LED_CONTROLLER_H
#define LED_CONTROLLER_H

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>

// LED 配置
#define LED_COUNT          60
#define LED_TYPE           NEO_GRB + NEO_KHZ800
#define LED_PIN            48
#define DEFAULT_BRIGHTNESS  50

// 灯效模式
enum LightMode {
  MODE_OFF = 0,
  MODE_BREATHING = 1,
  MODE_CONSTANT = 2,
  MODE_BLINKING = 3,
  MODE_RAINBOW = 4,
  MODE_CHASE = 5,
  MODE_THEFT_ALARM = 6,
  MODE_BRAKE = 7,
  MODE_TURN_LEFT = 8,
  MODE_TURN_RIGHT = 9,
  MODE_EMERGENCY = 10
};

// 颜色定义
struct RGBColor {
  uint8_t r;
  uint8_t g;
  uint8_t b;
};

// 预定义颜色
const RGBColor COLOR_RED = {255, 0, 0};
const RGBColor COLOR_GREEN = {0, 255, 0};
const RGBColor COLOR_BLUE = {0, 0, 255};
const RGBColor COLOR_WHITE = {255, 255, 255};
const RGBColor COLOR_YELLOW = {255, 255, 0};
const RGBColor COLOR_ORANGE = {255, 165, 0};
const RGBColor COLOR_PURPLE = {128, 0, 128};

class LEDController {
public:
  LEDController();
  void begin();
  void update();
  
  // 基本控制
  void setMode(LightMode mode);
  void setColor(RGBColor color);
  void setBrightness(uint8_t brightness);
  void turnOff();
  
  // 灯效控制
  void setSpeed(float speed);
  void setBrake(bool braking);
  void setTurnLeft(bool left);
  void setTurnRight(bool right);
  void setTheftAlarm(bool alarm);
  void setEmergency(bool emergency);
  void setRadarWarning(bool warning);
  
  // 获取当前状态
  LightMode getMode() { return currentMode; }
  RGBColor getCurrentColor() { return currentColor; }
  uint8_t getBrightness() { return strip.getBrightness(); }
  
private:
  Adafruit_NeoPixel strip;
  LightMode currentMode;
  RGBColor currentColor;
  float currentSpeed;
  bool isBraking;
  bool isTurningLeft;
  bool isTurningRight;
  bool isTheftAlarm;
  bool isEmergency;
  bool isRadarWarning;
  
  // 内部函数
  void breathingEffect();
  void blinkingEffect();
  void rainbowEffect();
  void chaseEffect();
  void theftAlarmEffect();
  void brakeEffect();
  void turnEffect(bool left);
  void emergencyEffect();
  void radarWarningEffect();
  
  // 辅助函数
  uint32_t rgbToUint32(RGBColor color);
  void fillStrip(RGBColor color);
  void clearStrip();
};

#endif // LED_CONTROLLER_H