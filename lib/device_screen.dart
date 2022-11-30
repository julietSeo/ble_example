import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.device});

  final BluetoothDevice device;


  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {

  FlutterBluePlus fBle = FlutterBluePlus.instance;

  String state = 'Connecting';
  String buttonText = 'Disconnect';

  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  StreamSubscription<BluetoothDeviceState>? _stateListener;

  List<BluetoothService> bluetoothService = [];

  @override
  void initState() {
    super.initState();

    _stateListener = widget.device.state.listen((event) {
      debugPrint('event: $event');

      if(deviceState == event) {
        return;
      }

      setBleConnectionState(event);
    });

    connect();
  }

  @override
  void dispose() {
    _stateListener?.cancel();

    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  ///연결 상태 갱신
  setBleConnectionState(BluetoothDeviceState event) {
    switch(event) {
      case BluetoothDeviceState.disconnected:
        state = 'Disconnected';
        buttonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        state = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        state = 'Connected';
        buttonText = 'Disconnect';
        break;
      case BluetoothDeviceState.connecting:
        state = "Connecting";
        break;
    }
    deviceState = event;
    setState(() { });
  }

  ///start connecting
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      state = "Connecting";
    });

    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 10000), onTimeout: (){
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();

      if(returnValue == null) {
        debugPrint('connection successful');
        List<BluetoothService> bleServices = await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });

        for(BluetoothService service in bleServices) {
          print("Service UUID: ${service.uuid}");
        }

        returnValue = Future.value(true);
      }
    });

    return returnValue?? Future.value(false);
  }

  ///disconnecting
  void disconnect() {
    try {
      setState(() {
        state = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Widget showInfo(BluetoothService bs) {
    String name = '';

    for(BluetoothCharacteristic c in bs.characteristics) {
      name += 't\t${c.uuid}\n';
    }

    return Text(name);
  }

  Widget serviceUUID(BluetoothService bs) {
    String name = '';
    name = bs.uuid.toString();
    return Text(name);
  }

  Widget listItem(BluetoothService bs) {
    return ListTile(
      onTap: null,
      title: serviceUUID(bs),
      subtitle: showInfo(bs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('$state'),
                  OutlinedButton(
                      onPressed: () {
                        if(deviceState == BluetoothDeviceState.connected) {
                          disconnect();
                        } else if(deviceState == BluetoothDeviceState.disconnected) {
                          connect();
                        }
                      },
                      child: Text(buttonText)
                  ),
                ],
            ),
            Expanded(
                child: ListView.separated(
                    itemBuilder: (context, index){
                      return listItem(bluetoothService[index]);
                    },
                    separatorBuilder: (BuildContext context, int index){
                      return Divider();
                    },
                    itemCount: bluetoothService.length)
            )
          ],
        ),
      ),
    );
  }
}