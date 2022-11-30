import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'device_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus fBle = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();

    init();
  }

  void init() {
    fBle.isScanning.listen((isScanning) {
      _scanning = isScanning;
      setState(() {
        //TODO: set UI changes
      });
    });
  }

  /// scan function
  void scan() async {
    if (await Permission.bluetoothScan.request().isGranted) {}
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetoothScan,
      Permission.location,
      Permission.bluetoothConnect
    ].request();
    print(status[Permission.bluetoothScan]);

    if (!_scanning) {
      scanResultList.clear();
      fBle.startScan(timeout: Duration(seconds: 4));
      fBle.scanResults.listen((result) {
        scanResultList = result;
        setState(() {
          //TODO: set UI changes
        });
      });
    } else {
      fBle.stopScan();
    }
  }

  void onTap(ScanResult sr) {
    print(sr.device.name);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: sr.device)),
    );
  }

  Widget deviceMacAddress(ScanResult sr) {
    return Text(sr.device.id.id);
  }

  Widget deviceName(ScanResult sr) {
    String name = "";

    if (sr.device.name.isNotEmpty) {
      name = sr.device.name;
    } else if (sr.advertisementData.localName.isNotEmpty) {
      name = sr.advertisementData.localName;
    } else {
      name = "No Name";
    }

    return Text(name);
  }

  Widget leading(ScanResult sr) {
    return const CircleAvatar(
      backgroundColor: Colors.deepOrangeAccent,
      child: Icon(Icons.bluetooth, color: Colors.white),
    );
  }

  Widget listItem(ScanResult sr) {
    return ListTile(
      onTap: () => onTap(sr),
      leading: leading(sr),
      title: deviceName(sr),
      subtitle: deviceMacAddress(sr),
    );
  }

  /// UI settings
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.separated(
            itemBuilder: (context, index) {
              return listItem(scanResultList[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
            itemCount: scanResultList.length),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => scan(),
        child: Icon(_scanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
