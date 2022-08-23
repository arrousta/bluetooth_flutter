import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DetailPage extends StatefulWidget {
  final BluetoothDevice server;

  const DetailPage({required this.server});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;

  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  String? _selectedFrameSize;
  int contentLength = 0;

  @override
  void initState() {
    super.initState();
    _selectedFrameSize = '0';
    _getBTConnection();
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    super.dispose();
  }

  _getBTConnection() {
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      isConnecting = false;
      isDisconnecting = false;
      setState(() {});
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally');
        } else {
          print('Disconnecting remotely');
        }
        if (this.mounted) {
          setState(() {});
        }
        Navigator.of(context).pop();
      });
    }).catchError((error) {
      Navigator.of(context).pop();
    });
  }

  //---------------------------------------------------------------------------------------
  List<String> receiveDataListString = [];
  StringBuffer rData  = StringBuffer();
  void _onDataReceived(Uint8List data) {
    if (data != null && data.length > 0) {
      contentLength += data.length;
    }
    Uint8List buffer = Uint8List(data.length);
    int bufferIndex = buffer.length;
    for (int i = data.length - 1; i >= 0; i--) {
          buffer[--bufferIndex] = data[i];
    }

    // Create message if there is new line character
    receiveDataListString.add(String.fromCharCodes(buffer));
    String dataString = String.fromCharCodes(buffer);
    rData.write(dataString);
    if(rData.toString().contains('<') && rData.toString().contains('>')){
      print("R_Data : ${rData.toString()}");
      rData.clear();
    }
    print("dataString: ${dataString}");
    // print("DataString ***: ${receiveDataListString}");
  }
//---------------------------------------------------------------------------------------


  void _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;
      } catch (e) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ${widget.server.name} ...')
              : isConnected
              ? Text('Connected with ${widget.server.name}')
              : Text('Disconnected with ${widget.server.name}')),
        ),
        body: SafeArea(
          child: isConnected
              ? Column(
            children: <Widget>[
              // selectFrameSize(),
              shotButton(),
            ],
          )
              : Center(
            child: Text(
              "Connecting...",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ));
  }

  Widget shotButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          _sendMessage('<MPU>');
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Send Data',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}