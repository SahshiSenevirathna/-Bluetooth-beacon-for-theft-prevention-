import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Simulator',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 3, 1, 8),
        scaffoldBackgroundColor: Colors.black,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FakeDevice {
  final String id;
  final String name;
  final int rssi;
  FakeDevice(this.id, this.name, this.rssi);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<FakeDevice> _devices = [];
  FakeDevice? _selected;
  String _connStatus = 'Disconnected';
  bool _scanning = false;
  Timer? _scanTimer;

  late AnimationController _scanAnimController;
  late AnimationController _bgAnimController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanAnimController.dispose();
    _bgAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _findDevices() {
    if (_scanning) return;
    setState(() {
      _devices.clear();
      _scanning = true;
      _connStatus = 'Disconnected';
      _selected = null;
    });

    final sample = [
      FakeDevice('AA:BB:CC:01', 'Beacon One', -45),
      FakeDevice('AA:BB:CC:02', 'Beacon Two', -62),
      FakeDevice('AA:BB:CC:03', '(unknown)', -78),
      FakeDevice('AA:BB:CC:04', 'My Beacon', -50),
    ];

    int idx = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (idx < sample.length) {
        setState(() => _devices.add(sample[idx]));
        idx++;
      } else {
        t.cancel();
        setState(() => _scanning = false);
      }
    });
  }

  void _showBeaconDetails() {
    if (_selected == null) {
      _showSnack('Select a device first');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BeaconDetailsPage(device: _selected!)),
    );
  }

  Future<void> _connectBeacon() async {
    if (_selected == null) {
      _showSnack('Select a device first');
      return;
    }

    setState(() => _connStatus = 'Connecting...');
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _connStatus = 'Connected');
    _showSnack(
      'Connected to ${_selected!.name.isEmpty ? _selected!.id : _selected!.name}',
    );
  }

  void _showSnack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 60, 38, 118),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Simulator'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 16, 5, 67),
      ),
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          final colorShift = _bgAnimController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color.fromARGB(255, 54, 27, 173),
                    Colors.black,
                    colorShift,
                  )!,
                  Color.lerp(
                    const Color.fromARGB(255, 20, 31, 153),
                    const Color.fromARGB(255, 32, 40, 45),
                    colorShift,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _customButton(
                    icon: _scanning
                        ? RotationTransition(
                            turns: _scanAnimController,
                            child: const Icon(Icons.sync),
                          )
                        : const Icon(Icons.search),
                    label: _scanning ? 'Scanning...' : 'Find Devices',
                    color: _scanning
                        ? Colors.grey[800]!
                        : const Color.fromARGB(255, 99, 24, 165),
                    onPressed: _scanning ? null : _findDevices,
                  ),
                  _customButton(
                    icon: const Icon(Icons.info_outline),
                    label: 'Show Beacon',
                    color: const Color.fromARGB(255, 121, 63, 18),
                    onPressed: _showBeaconDetails,
                  ),
                  _customButton(
                    icon: const Icon(Icons.bluetooth_connected),
                    label: 'Connect',
                    color: const Color.fromARGB(255, 38, 153, 86),
                    onPressed: _connectBeacon,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Card(
                color: Colors.grey[850]!.withOpacity(0.95),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: _connStatus == 'Connected'
                      ? const Icon(
                          Icons.check_circle,
                          color: Color.fromARGB(255, 86, 106, 96),
                        )
                      : const Icon(Icons.usb, color: Colors.redAccent),
                  title: const Text(
                    'Connection Status',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _connStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _connStatus == 'Connected'
                          ? const Color.fromARGB(255, 32, 72, 53)
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Discovered Devices (tap to select):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _devices.isEmpty
                    ? const Center(
                        child: Text(
                          'No devices found.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, i) {
                          final d = _devices[i];
                          final selected = _selected?.id == d.id;
                          return _deviceCard(d, selected);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customButton({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: color,
        elevation: 6,
        shadowColor: color.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }

  Widget _deviceCard(FakeDevice d, bool selected) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, glow, child) {
        return ScaleTransition(
          scale: selected ? _pulseController : const AlwaysStoppedAnimation(1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        const Color.fromARGB(
                          255,
                          81,
                          154,
                          119,
                        ).withOpacity(0.4 + 0.3 * glow),
                        Colors.lightGreenAccent.withOpacity(0.4 + 0.3 * glow),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? Colors.greenAccent.withOpacity(0.7 + 0.3 * glow)
                      : Colors.black38,
                  blurRadius: selected ? 14 + 6 * glow : 4,
                  spreadRadius: selected ? 2 + 2 * glow : 1,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                d.name.isEmpty ? '(unknown)' : d.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'ID: ${d.id}\nRSSI: ${d.rssi}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
              onTap: () => setState(() => _selected = d),
            ),
          ),
        );
      },
    );
  }
}

class BeaconDetailsPage extends StatelessWidget {
  final FakeDevice device;
  const BeaconDetailsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Details'),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.grey[850]!.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device ID: ${device.id}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Name: ${device.name}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'RSSI: ${device.rssi}',
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'This is a simulated beacon. No real Bluetooth connection is made.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
