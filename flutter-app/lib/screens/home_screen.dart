import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ControlScreen(),
    const MapScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [
          Icons.dashboard,
          Icons.control_camera,
          Icons.map,
          Icons.settings,
        ],
        activeIndex: _currentIndex,
        activeColor: Colors.blue,
        inactiveColor: Colors.grey,
        gapLocation: GapLocation.center,
        notchMargin: 8.0,
        leftCornerRadius: 32.0,
        rightCornerRadius: 32.0,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能单车尾灯'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              // 蓝牙连接状态
            },
          ),
          IconButton(
            icon: const Icon(Icons.battery_full),
            onPressed: () {
              // 电池状态
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 20),
            _buildSpeedCard(context),
            const SizedBox(height: 20),
            _buildBatteryCard(context),
            const SizedBox(height: 20),
            _buildLightEffectCard(context),
            const SizedBox(height: 20),
            _buildRecentActivityCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('设备状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('已连接', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            const Text('在线', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedCard(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('当前速度', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('0', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text(' km/h', style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryCard(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.battery_full, color: Colors.green),
                const SizedBox(width: 8),
                const Text('电池电量', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.8,
                    backgroundColor: Colors.grey[600],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('80%', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('预计续航: 6小时', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLightEffectCard(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.yellow),
                const SizedBox(width: 8),
                const Text('当前灯效', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLightEffectButton('常亮', Colors.red),
                _buildLightEffectButton('呼吸', Colors.orange),
                _buildLightEffectButton('闪烁', Colors.yellow),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLightEffectButton(String name, Color color) {
    return ElevatedButton(
      onPressed: () {
        // 切换灯效
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(name),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('最近活动', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.directions_bike, color: Colors.blue, size: 20),
              title: Text('开始骑行'),
              subtitle: Text('10分钟前'),
            ),
            const ListTile(
              leading: Icon(Icons.warning, color: Colors.orange, size: 20),
              title: Text('检测到来车'),
              subtitle: Text('15分钟前'),
            ),
            const ListTile(
              leading: Icon(Icons.brake, color: Colors.red, size: 20),
              title: Text('刹车灯效'),
              subtitle: Text('25分钟前'),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('灯效控制'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildControlCard('常亮', Icons.lightbulb, Colors.red),
          _buildControlCard('呼吸', Icons.opacity, Colors.orange),
          _buildControlCard('闪烁', Icons.flash_on, Colors.yellow),
          _buildControlCard('彩虹', Icons.color_lens, Colors.purple),
          _buildControlCard('刹车', Icons.brake, Colors.red),
          _buildControlCard('左转', Icons.turn_left, Colors.blue),
          _buildControlCard('右转', Icons.turn_right, Colors.blue),
          _buildControlCard('紧急', Icons.warning, Colors.red),
        ],
      ),
    );
  }

  Widget _buildControlCard(String title, IconData icon, Color color) {
    return Card(
      color: Colors.grey[800],
      child: InkWell(
        onTap: () {
          // 应用灯效
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行轨迹'),
      ),
      body: const Center(
        child: Text('地图功能开发中...'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingItem('蓝牙设置', Icons.bluetooth),
          _buildSettingItem('亮度设置', Icons.brightness_6),
          _buildSettingItem('灵敏度设置', Icons.tune),
          _buildSettingItem('固件更新', Icons.system_update),
          _buildSettingItem('关于', Icons.info),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: () {
        // 打开设置页面
      },
    );
  }
}