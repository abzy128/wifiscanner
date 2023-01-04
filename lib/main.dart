import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sound_generator/waveTypes.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:signal_strength_indicator/signal_strength_indicator.dart';
import 'dart:math';
import 'package:sound_generator/sound_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool play = true;
  List<BluetoothDevice> bluetoothDevices = <BluetoothDevice>[];
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool get isStreaming => subscription != null;
  Timer? timer;
  Timer? updateTimer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
        const Duration(seconds: 5), (Timer t) => _startScan(context));
  }

  void _startTimer() {
    updateTimer = Timer.periodic(
        const Duration(seconds: 1), (Timer t) => _updateScan(context));
  }

  void _playSound(WiFiAccessPoint accessPoint) {
    
  }

  Future<void> _startScan(BuildContext context) async {
    final can = await WiFiScan.instance.canStartScan();
    if (can != CanStartScan.yes) {
      if (mounted) kShowSnackBar(context, "Cannot start scan: $can");
      return;
    }

    final result = await WiFiScan.instance.startScan();
    if (mounted) kShowSnackBar(context, "startScan: $result");
    //setState(() => accessPoints = <WiFiAccessPoint>[]);
  }

  Future<void> _updateScan(BuildContext context) async {}

  Future<bool> _canGetScannedResults(BuildContext context) async {
    final can = await WiFiScan.instance.canGetScannedResults();
    if (can != CanGetScannedResults.yes) {
      if (mounted) kShowSnackBar(context, "Cannot get scanned results: $can");
      accessPoints = <WiFiAccessPoint>[];
      return false;
    }

    return true;
  }

  Future<void> _getScannedResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      final results = await WiFiScan.instance.getScannedResults();
      setState(() => accessPoints = results);
    }
  }

  Future<void> _startListeningToScanResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result) => setState(() => accessPoints = result));
    }
  }

  void _stopListeningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }

  @override
  void dispose() {
    SoundGenerator.release();
    timer?.cancel();
    _stopListeningToScanResults();
    super.dispose();
  }

  Widget _buildToggle({
    String? label,
    bool value = false,
    ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) =>
      Row(
        children: [
          if (label != null) Text(label),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Wifi Scanner'),
              actions: [
                IconButton(
                  icon: (play) ? Icon(Icons.volume_up) : Icon(Icons.volume_off),
                  onPressed: () => setState(() => play = !play),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _getScannedResults(context),
                ),
                _buildToggle(
                  label: "Сканировать",
                  value: isStreaming,
                  onChanged: (value) {
                    if (value) {
                      _startListeningToScanResults(context);
                    } else {
                      _stopListeningToScanResults();
                    }
                  },
                  activeColor: Colors.green,
                ),
              ],
              bottom: const TabBar(tabs: [
                Tab(
                  icon: Icon(Icons.wifi),
                ),
                Tab(
                  icon: Icon(Icons.bluetooth),
                ),
                Tab(icon: Icon(Icons.radar)),
              ]),
            ),
            body: TabBarView(
              children: [
                Scaffold(
                  body: Builder(
                    builder: (context) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Center(
                                child: accessPoints.isEmpty
                                    ? const Text("Нет доступных сетей")
                                    : ListView.builder(
                                        itemCount: accessPoints.length,
                                        itemBuilder: (context, i) =>
                                            _AccessPointTile(
                                                accessPoint: accessPoints[i])),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
                Scaffold(
                    body: Builder(
                        builder: (context) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                        child: Center(
                                            child: const Text("В разработке"))),
                                  ]),
                            ))),
                Scaffold(
                    body: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                              child: Center(child: const Text("В разработке")))
                        ]),
                  ),
                ))
              ],
            )),
      ),
    ));
  }
}

class _AccessPointTile extends StatelessWidget {
  final WiFiAccessPoint accessPoint;

  const _AccessPointTile({Key? key, required this.accessPoint})
      : super(key: key);

  Widget _buildInfo(String label, dynamic value) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(value.toString()))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title =
        accessPoint.ssid.isNotEmpty ? accessPoint.ssid : "Неизвестная сеть";
    final signalIcon = accessPoint.level >= -80
        ? Icons.signal_wifi_4_bar
        : Icons.signal_wifi_0_bar;
    return ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(signalIcon),
        title: Text(title),
        subtitle: Text(accessPoint.capabilities),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -45 * pi / 180,
                    origin: const Offset(-15, 0),
                    child: SignalStrengthIndicator.sector(
                      value: (accessPoint.level * -1 + 10) / 100,
                      size: 100,
                      spacing: -0.01,
                    ),
                  ),
                  const Divider(),
                  _buildInfo("Название", accessPoint.ssid),
                  _buildInfo("MAC адрес", accessPoint.bssid),
                  _buildInfo("Возможности", accessPoint.capabilities),
                  _buildInfo("Примерное расстояние",
                      "${((27.55 - (20 * log(accessPoint.frequency)) + accessPoint.level.abs()) / -5.0).toStringAsFixed(1)} метр"),
                  _buildInfo("Частота", "${accessPoint.frequency}MHz"),
                  _buildInfo("Уровень сигнала", "${accessPoint.level}dBm"),
                  _buildInfo("Стандарт сети", accessPoint.standard),
                  _buildInfo("Частота", "${accessPoint.centerFrequency0}MHz"),
                  _buildInfo("Ширина канала", "${accessPoint.channelWidth}MHz"),
                ],
              ),
            ),
          );
        });
  }
}

void kShowSnackBar(BuildContext context, String message) {
  if (kDebugMode) print(message);
  //ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
