# 🚲 智能单车尾灯 — 完整方案

> 版本：v1.0 | 日期：2026-04-02

---

## 一、项目概述

一款基于 ESP32-S3 的智能单车尾灯，通过 IMU、霍尔传感器、GPS 等多维感知骑行状态，实现刹车/加速/转弯等场景的自动灯光指示，并通过 BLE 连接手机 App 实现数据可视化、轨迹记录和参数配置。

### 核心特性

- **智能灯效**：自动识别刹车/加速/左转/右转/停车，对应不同 LED 动画
- **实时数据**：速度、加速度、车身倾角、GPS 轨迹
- **来车提醒**：后向雷达检测，尾灯 + 手机双重提醒
- **防盗报警**：停车后震动检测，BLE 范围内手机推送
- **日间/夜间自适应**：光敏电阻自动调节亮度
- **手机 App**：Flutter 跨平台，实时仪表盘 + 轨迹 + 设置
- **BLE OTA**：无需拆车，蓝牙直接升级固件

### 设计原则

- **尾灯独立工作**：没有手机也能正常运行所有灯效
- **模块化**：各传感器独立，可裁剪，后期可扩展 4G 模块
- **低功耗**：智能休眠策略，续航 ≥8 小时
- **防水防震**：3D 打印外壳 + 硅胶密封

---

## 二、硬件设计

### 2.1 硬件清单（BOM）

| 序号 | 组件 | 推荐型号 | 数量 | 单价(¥) | 小计(¥) | 说明 |
|------|------|---------|------|---------|---------|------|
| 1 | 主控 | ESP32-S3-WROOM-1 (N8R8) | 1 | 15 | 15 | 双核 240MHz, 8MB PSRAM |
| 2 | IMU | ICM-20948 (九轴) | 1 | 20 | 20 | 加速度计+陀螺仪+磁力计 |
| 3 | 测速传感器 | A3144 霍尔传感器 + 钕铁硼磁铁 | 1套 | 5 | 5 | 轮圈贴磁铁，车架装霍尔 |
| 4 | LED 灯带 | WS2812B 144LED/m | 0.3m | 15/m | 5 | 可独立寻址，60+ LED |
| 5 | 来车检测 | HLK-LD2410 微波雷达 | 1 | 20 | 20 | 抗光干扰，2-6m |
| 6 | GPS | ATGM336H-5N | 1 | 15 | 15 | 精度 2.5m，低功耗 |
| 7 | 光敏电阻 | GL5528 + 10K 分压电阻 | 1 | 1 | 1 | 日间/夜间自动切换 |
| 8 | 电池 | 18650 3000mAh × 2 并联 | 2 | 10 | 20 | 6000mAh 总容量 |
| 9 | BMS | 2S 18650 保护板 | 1 | 5 | 5 | 过充过放保护 |
| 10 | 充电 | TP4056 × 2（或双路充电板） | 1 | 5 | 5 | USB-C 输入 |
| 11 | 稳压 | AMS1117-3.3V | 1 | 1 | 1 | 给 ESP32 供电 |
| 12 | 外壳 | 3D 打印（PETG/ABS） | 1 | — | — | 含硅胶密封圈 |
| 13 | 其他 | 排针、杜邦线、热缩管、螺丝等 | 1套 | 10 | 10 | |
| | | | | **总计** | **~¥122** | |

### 2.2 接口分配

```
ESP32-S3 引脚分配：

I2C 总线:
  SDA  → GPIO8    (IMU + 可扩展)
  SCL  → GPIO9    (IMU + 可扩展)

SPI 总线 (LED):
  MOSI → GPIO47   (WS2812B 数据线，也支持单线协议)
                     实际 WS2812B 用 RMT 外设驱动，接 GPIO48

UART:
  TX   → GPIO43   → GPS RX (ATGM336H)
  RX   → GPIO44   ← GPS TX (ATGM336H)
  TX2  → GPIO17   → 雷达 RX (LD2410) [可选UART方式]
  RX2  → GPIO18   ← 雷达 TX (LD2410) [可选UART方式]

中断:
  GPIO4  ← 霍尔传感器 (外部中断，上升沿)

模拟:
  ADC1_CH0 (GPIO1)  ← 光敏电阻分压
  ADC1_CH3 (GPIO3)  ← 电池电压分压 (监控电量)

RMT (WS2812B):
  GPIO48  → WS2812B 数据线

BLE/WiFi:
  内置，无需额外引脚
```

### 2.3 功耗分析

| 组件 | 工作电流 | 说明 |
|------|---------|------|
| ESP32-S3 (BLE连接) | ~15mA | 双核运行 |
| ICM-20948 | ~5mA | 低功耗模式 |
| WS2812B (中亮，40颗) | ~100mA | 最大功耗点 |
| HLK-LD2410 | ~20mA | 持续监测 |
| ATGM336H | ~25mA | 可停车时断电省电 |
| 其他 (BMS/稳压损耗) | ~10mA | |
| **骑行总功耗** | **~175mA** | |

**续航估算：** 6000mAh / 175mA ≈ **34 小时理论**，实际考虑效率损耗约 **20-25 小时**

**优化策略：**
- 停车后 GPS 断电（省 25mA）
- LED 降低到 30% 亮度或关闭（省 70mA）
- ESP32 进入 light sleep，BLE 保持广播
- 停车总功耗降至 ~30mA → 待机可达 **200 小时**

---

## 三、固件设计

### 3.1 软件架构

```
firmware/
├── main/
│   └── main.c                    # 入口 + FreeRTOS 任务调度
│
├── sensors/
│   ├── imu.c / imu.h             # ICM-20948 驱动 + 姿态解算
│   ├── hall.c / hall.h           # 霍尔传感器测速
│   ├── radar.c / radar.h         # LD2410 雷达来车检测
│   ├── gps.c / gps.h             # ATGM336H GPS 解析
│   └── light_sensor.c / light_sensor.h  # 光敏电阻
│
├── state_machine/
│   ├── bike_state.c / bike_state.h     # 骑行状态机核心
│   └── bike_state_config.h             # 状态判断阈值参数
│
├── effects/
│   ├── led_driver.c / led_driver.h     # WS2812B RMT 驱动
│   ├── effects.c / effects.h           # 灯效动画库
│   └── effects_config.h                # 灯效参数（颜色/亮度/速度）
│
├── ble/
│   ├── ble_service.c / ble_service.h   # BLE GATT 服务
│   └── ble_gatts_config.h              # UUID 和特征值定义
│
├── storage/
│   ├── nvs_storage.c / nvs_storage.h   # NVS 参数存储
│   ├── track_logger.c / track_logger.h # 轨迹数据记录到 flash
│   └── ota.c / ota.h                   # BLE OTA 升级
│
├── power/
│   ├── battery.c / battery.h           # 电量监测
│   └── sleep.c / sleep.h               # 低功耗管理
│
└── utils/
    ├── kalman_filter.c / kalman_filter.h   # 卡尔曼滤波
    ├── complementary_filter.c              # 互补滤波（备选）
    └── moving_average.c                    # 移动平均滤波
```

### 3.2 FreeRTOS 任务划分

```
核心 0（实时控制）:
  ┌─ task_imu_read      优先级:5  周期:5ms    → 读 IMU 原始数据
  ├─ task_state_machine 优先级:4  周期:20ms   → 状态判断（刹车/转弯/加速）
  ├─ task_led_update    优先级:3  周期:33ms   → LED 动画刷新 (30fps)
  ├─ task_hall_speed    优先级:5  触发:中断   → 霍尔脉冲计数 → 速度计算
  └─ task_radar         优先级:2  周期:50ms   → 来车检测

核心 1（通信与外设）:
  ├─ task_ble           优先级:4  事件驱动     → BLE 通信
  ├─ task_gps           优先级:3  周期:100ms   → GPS 数据解析
  ├─ task_battery       优先级:1  周期:10s     → 电量监测
  └─ task_track_log     优先级:2  周期:1s      → 轨迹点存储
```

### 3.3 状态机设计

```
                    ┌─────────┐
                    │  IDLE   │ ← 上电默认 / 停车超时
                    │ (停车)   │
                    └────┬────┘
                         │ 速度 > 2km/h
                         ▼
                    ┌─────────┐
              ┌────│ CRUISING │────┐
              │    │ (匀速)   │    │
              │    └────┬────┘    │
              │         │         │
        刹车/减速    加速度变化   侧倾/角速度
              │         │         │
              ▼         ▼         ▼
        ┌─────────┐ ┌─────────┐ ┌───────────┐
        │ BRAKING │ │ACCELING │ │  TURNING  │
        │  (刹车) │ │ (加速)  │ │ (左/右转) │
        └────┬────┘ └────┬────┘ └─────┬─────┘
             │           │            │
             │           │      转弯结束
             │           │            │
             │     加速度回落          │
             │           │            │
             └─────┬─────┘────────────┘
                   │ 恢复匀速条件
                   ▼
              ┌─────────┐
              │ CRUISING │
              └─────────┘
                   │ 速度 < 2km/h 持续 5s
                   ▼
              ┌─────────┐
              │  IDLE   │
              │ (停车)   │
              └─────────┘
```

### 3.4 状态判断算法

**刹车检测（多条件融合）：**
```
条件1: 加速度计 Y轴 < -2.0 m/s² （前向减速）
条件2: 霍尔速度下降率 > 3 km/h/s
条件3: 当前速度 > 5 km/h （排除静止抖动）

满足任一条件 → 进入 BRAKING 状态
两个条件同时满足 → 进入 HARD_BRAKING（急刹，爆闪）
```

**转弯检测：**
```
条件1: 陀螺仪 Z轴角速度绝对值 > 15 °/s
条件2: 侧向加速度 > 1.5 m/s²
条件3: 当前速度 > 5 km/h

Z轴 > 0 → 左转，Z轴 < 0 → 右转
同时满足条件1+条件3 即判定转弯
```

**加速检测：**
```
条件: 加速度计 Y轴 > 1.5 m/s² 且持续 > 0.5s
→ 进入 ACCELING 状态
```

**参数通过 BLE 可调**，存储在 NVS 中，不用重新烧录固件。

### 3.5 LED 灯效设计

```
尾灯布局（俯视图，约 60 颗 LED）：

   1  2  3  4  5  6  7  8  9  10    ← 段A：左转箭头区
  11 12 13 14 15 16 17 18 19 20
  21 22 23 24 25 26 27 28 29 30    ← 段B：主体刹车/示宽
  31 32 33 34 35 36 37 38 39 40
  41 42 43 44 45 46 47 48 49 50    ← 段C：右转箭头区
  51 52 53 54 55 56 57 58 59 60

灯效动画：

IDLE（停车）：
  段B 红色慢闪烁 (1Hz, 50% duty)

CRUISING（匀速）：
  段B 红色常亮 (80% 亮度) + 微弱呼吸效果

BRAKING（刹车）：
  段B 全部 LED 红色 100% 高频闪烁 (4Hz)
  [+段A+段C 红色同步闪烁]

HARD_BRAKING（急刹）：
  全部 LED 红色爆闪 (8Hz) + 白色闪烁交替

ACCELING（加速）：
  段B 绿色波浪从中心向两侧扩散（速度感）

LEFT_TURN（左转）：
  段A 橙色箭头动画 ◄◄◄◄（从右向左流动）
  段B 红色常亮
  段C 熄灭

RIGHT_TURN（右转）：
  段C 橙色箭头动画 ►►►►（从左向右流动）
  段B 红色常亮
  段A 熄灭

REAR_APPROACH（后方来车）：
  段B 红色快速脉冲闪烁提醒骑手
  亮度根据距离递减（越近越亮）
```

### 3.6 防盗模式

```
触发条件: 停车(IDLE) > 30s 且手动开启防盗

检测逻辑:
  IMU 加速度计 → 震动检测
    峰值 > 阈值 → 触发报警

报警动作:
  1. WS2812B 红白交替爆闪（威慑）
  2. BLE 广播紧急通知（手机收到震动提醒）
  3. 震动计数 + 时间戳记录到 flash
  4. GPS 记录当前位置（如果 GPS 模块在线）

解除:
  手机 BLE 连接并解锁
  或 物理按钮长按 5s
```

---

## 四、BLE 通信协议

### 4.1 GATT 服务定义

```
Service 1: 骑行数据 (UUID: 0000FFE0-...)
├── Char 0xFFE1: Speed        (Notify)  uint16, 单位 0.1 km/h
├── Char 0xFFE2: Acceleration (Notify)  3×int16, x/y/z 单位 0.01 m/s²
├── Char 0xFFE3: Gyroscope    (Notify)  3×int16, x/y/z 单位 0.01 °/s
├── Char 0xFFE4: BikeState    (Notify)  uint8 枚举值 (见下)
├── Char 0xFFE5: TiltAngle    (Notify)  int16, 单位 0.1°
├── Char 0xFFE6: Battery      (Notify)  uint8, 百分比 0-100
├── Char 0xFFE7: RearDist     (Notify)  uint16, 后方目标距离 cm (0=无目标)
├── Char 0xFFE8: LightLevel   (Notify)  uint8, 环境亮度 0-255

Service 2: GPS 数据 (UUID: 0000FFE1-...)
├── Char 0xFFE1: GPS_Location (Notify)  4×int32: lat(0.000001°), lon(0.000001°), alt(m), speed(0.1km/h)
├── Char 0xFFE2: GPS_SatInfo  (Notify)  uint8 卫星数, uint8 fix状态
├── Char 0xFFE3: TrackPoint   (Indicate) 触发批量传输轨迹点

Service 3: 控制 (UUID: 0000FFE2-...)
├── Char 0xFFE1: Config       (Write)   JSON 配置参数
├── Char 0xFFE2: LedMode      (Write)   uint8, 灯效模式选择
├── Char 0xFFE3: AntiTheft    (Write)   uint8, 0=关 1=开
├── Char 0xFFE4: CmdAck       (Notify)  操作确认回执

Service 4: OTA (UUID: 0000FEF5-...)
├── Char 0xFEF6: OtaControl   (Write)   开始/结束/校验
├── Char 0xFEF7: OtaData      (Write)   固件数据流
```

### 4.2 状态枚举

```c
typedef enum {
    STATE_IDLE          = 0,  // 停车
    STATE_CRUISING      = 1,  // 匀速骑行
    STATE_BRAKING       = 2,  // 刹车
    STATE_HARD_BRAKING  = 3,  // 急刹
    STATE_ACCELING      = 4,  // 加速
    STATE_LEFT_TURN     = 5,  // 左转
    STATE_RIGHT_TURN    = 6,  // 右转
    STATE_REAR_APPROACH = 7,  // 后方来车
    STATE_ANTI_THEFT    = 8,  // 防盗报警
} BikeState;
```

---

## 五、手机 App 设计

### 5.1 技术栈

- **框架**: Flutter 3.x (Dart)
- **BLE 插件**: flutter_reactive_ble
- **地图**: 高德地图 / Mapbox GL
- **图表**: fl_chart
- **状态管理**: Riverpod
- **本地存储**: shared_preferences + SQLite
- **平台**: iOS + Android

### 5.2 页面结构

```
App
├── 首页/仪表盘 (HomePage)
│   ├── 速度大字显示 + 状态指示
│   ├── 四宫格数据卡片 (速度/里程/均速/时长)
│   ├── 实时加速度曲线图
│   └── 来车提醒浮窗
│
├── 轨迹页 (TrackPage)
│   ├── 地图实时轨迹
│   ├── 历史骑行列表
│   ├── 骑行详情 (距离/时间/均速/爬升)
│   └── GPX 导出 / 分享
│
├── 设备页 (DevicePage)
│   ├── BLE 扫描 & 连接
│   ├── 电池电量
│   ├── 固件版本 & OTA 升级
│   └── 传感器原始数据查看（调试用）
│
├── 设置页 (SettingsPage)
│   ├── 灯效模式 & 亮度
│   ├── 刹车/转弯灵敏度阈值
│   ├── 防盗模式开关 & 灵敏度
│   ├── 来车检测开关 & 距离阈值
│   └── 报警历史记录
│
└── 关于页 (AboutPage)
```

### 5.3 核心功能

**实时仪表盘:**
- BLE Notify 接收数据，100ms 刷新
- 大号速度显示，根据状态变色（绿=加速，红=刹车，橙=转弯）
- 加速度实时曲线，最近 30 秒滑动窗口

**轨迹记录:**
- 骑行结束后 BLE Indicate 批量接收轨迹点
- 存入本地 SQLite
- 地图渲染轨迹，支持回放动画
- 导出 GPX 文件（兼容 Strava/Keep/行者）

**来车提醒:**
- 收到 REAR_APPROACH 状态 → 手机震动 + 屏幕闪烁提醒
- 显示后方目标距离

**OTA 升级:**
- 下载新固件到手机
- 通过 BLE 分包传输到 ESP32
- ESP32 校验写入 flash 并重启

---

## 六、开发路线图

### Phase 1：基础灯效（2 周）

```
目标：ESP32 + IMU + WS2812B，实现核心状态识别和灯效

硬件搭建:
  ✅ ESP32-S3 开发板
  ✅ ICM-20948 模块
  ✅ WS2812B 灯带
  ✅ 基础供电（USB 暂时供电）

固件:
  ✅ I2C 驱动 ICM-20948
  ✅ 互补滤波姿态解算
  ✅ 状态机（刹车/加速/转弯/停车）
  ✅ WS2812B RMT 驱动 + 基础灯效
  ✅ NVS 存储阈值参数

验证: 手持开发板模拟骑行姿态，验证灯效切换
```

### Phase 2：传感器扩展 + BLE（2 周）

```
硬件搭建:
  ✅ 霍尔传感器 + 磁铁（轮圈测速）
  ✅ HLK-LD2410 微波雷达
  ✅ ATGM336H GPS
  ✅ 光敏电阻
  ✅ 电池 + BMS + 充电模块

固件:
  ✅ 霍尔中断测速
  ✅ UART 雷达来车检测
  ✅ UART GPS NMEA 解析
  ✅ ADC 光敏 + 电池电压
  ✅ BLE GATT 服务完整实现
  ✅ 日间/夜间自动切换
  ✅ 防盗震动检测

验证: 实车安装测试，手机 nRF Connect 调试 BLE 数据
```

### Phase 3：手机 App（2-3 周）

```
App:
  ✅ BLE 扫描连接 + 数据解析
  ✅ 实时仪表盘 UI
  ✅ 轨迹记录 + 地图显示
  ✅ 设置页参数调节
  ✅ 防盗推送
  ✅ OTA 升级功能

验证: 实车骑行，App 端数据与实际对比
```

### Phase 4：外壳 & 优化（1-2 周）

```
✅ 3D 打印外壳设计（PETG 材质防水）
✅ 硅胶密封
✅ PCB 打样（可选，替代面包板）
✅ 功耗优化 + 长续航测试
✅ 实际道路测试，调优阈值
```

**总工期：7-9 周**（固件和 App Phase 2-3 可并行）

---

## 七、后期可扩展方向

| 功能 | 方案 | 难度 |
|------|------|------|
| 远程防盗追踪 | 加 Air780E Cat.1 + MQTT | ⭐⭐⭐ |
| 手动转向灯 | 车把蓝牙按钮 / 线控按钮 | ⭐ |
| 骑行社交 | 轨迹分享到微信/社交平台 | ⭐⭐ |
| 语音交互 | ESP32-S3 I2S 麦克风 + 离线唤醒词 | ⭐⭐⭐ |
| AI 姿态识别 | TinyML 模型替代阈值判断，更准确 | ⭐⭐⭐ |
| 车队模式 | 多车 BLE Mesh 通信，编队骑行 | ⭐⭐⭐⭐ |
| 太阳能充电 | 尾灯外壳集成小型太阳能板 | ⭐⭐ |

---

## 八、风险与注意事项

1. **IMU 振动噪声** — 车座下方振动大，必须做好低通滤波 + 卡尔曼滤波，否则误触发刹车
2. **来车检测准确性** — LD2410 微波雷达在低速骑行时可能误判地面/树木，需要调参
3. **防水** — WS2812B 灯带和 PCB 都要做好防水，建议灌封或全密封外壳
4. **GPS 冷启动** — ATGM336H 冷启动定位需要 30s+，热启动 1-3s，骑行中保持常开
5. **BLE 距离** — 实际环境大约 15-20m，人墙/金属车架会衰减，轨迹同步需要走近
6. **法规** — 确保尾灯颜色/亮度符合当地自行车灯具法规（通常红色后灯）
