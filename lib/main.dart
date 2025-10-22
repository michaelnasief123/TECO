
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TecoClockApp());
}

class TecoClockApp extends StatelessWidget {
  const TecoClockApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TECO Clock_V001',
      theme: ThemeData(useMaterial3: true),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _monthController = TextEditingController(text: DateTime.now().month.toString().padLeft(2,'0'));
  final _dayController = TextEditingController(text: DateTime.now().day.toString().padLeft(2,'0'));
  final _hourController = TextEditingController(text: DateTime.now().hour.toString().padLeft(2,'0'));
  final _minuteController = TextEditingController(text: DateTime.now().minute.toString().padLeft(2,'0'));
  final _secondController = TextEditingController(text: DateTime.now().second.toString().padLeft(2,'0'));

  bool _useSystemTime = false;
  int _brightness = 15;

  String _ip = '192.168.4.1';
  int _port = 2000;
  String _gateway = '192.168.4.1';
  String _subnet = '255.255.255.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ip = prefs.getString('ip') ?? _ip;
      _port = prefs.getInt('port') ?? _port;
      _gateway = prefs.getString('gateway') ?? _gateway;
      _subnet = prefs.getString('subnet') ?? _subnet;
    });
  }

  Future<void> _saveSettings(String ip, int port, String gateway, String subnet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    await prefs.setInt('port', port);
    await prefs.setString('gateway', gateway);
    await prefs.setString('subnet', subnet);
    setState(() {
      _ip = ip;
      _port = port;
      _gateway = gateway;
      _subnet = subnet;
    });
  }

  void _useSystemNow(bool? v) {
    if (v == null) return;
    setState(() {
      _useSystemTime = v;
      if (_useSystemTime) {
        final now = DateTime.now();
        _yearController.text = now.year.toString();
        _monthController.text = now.month.toString().padLeft(2, '0');
        _dayController.text = now.day.toString().padLeft(2, '0');
        _hourController.text = now.hour.toString().padLeft(2, '0');
        _minuteController.text = now.minute.toString().padLeft(2, '0');
        _secondController.text = now.second.toString().padLeft(2, '0');
      }
    });
  }

  int _computeWeekdayDigit(DateTime dt) {
    return dt.weekday; // Monday=1 .. Sunday=7
  }

  String _buildPacketString() {
    final year = _yearController.text.padLeft(4, '0');
    final month = _monthController.text.padLeft(2, '0');
    final day = _dayController.text.padLeft(2, '0');

    int hourInt = int.tryParse(_hourController.text) ?? 0;
    final hour = hourInt.toString().padLeft(2, '0');
    final minute = _minuteController.text.padLeft(2, '0');
    final second = _secondController.text.padLeft(2, '0');

    int weekdayDigit = 1;
    try {
      final dt = DateTime(int.parse(year), int.parse(month), int.parse(day));
      weekdayDigit = _computeWeekdayDigit(dt);
    } catch (_) {
      weekdayDigit = DateTime.now().weekday;
    }

    final ampm = (hourInt >= 12) ? '2' : '1';
    final bright = _brightness.toString().padLeft(2, '0');

    return '$year$month$day${weekdayDigit.toString()}$hour$minute$second$ampm$bright';
  }

  Future<void> _sendUdp() async {
    final packet = _buildPacketString();
    final bytes = packet.codeUnits;
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(bytes, InternetAddress(_ip), _port);
      socket.close();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Packet sent successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send packet: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TECO Clock_V001'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettingsDialog),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F3FF), Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.asset('assets/teco_logo.png', height: 100),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: Text('Date (Y-M-D)')),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_yearController, 'Year')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(_monthController, 'Month')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(_dayController, 'Day')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Align(alignment: Alignment.centerLeft, child: Text('Time (H:M:S)')),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_hourController, 'Hour')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(_minuteController, 'Min')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField(_secondController, 'Sec')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(value: _useSystemTime, onChanged: _useSystemNow),
                          const SizedBox(width: 8),
                          const Text('Use system time'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Align(alignment: Alignment.centerLeft, child: Text('Brightness')),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              min: 1,
                              max: 15,
                              divisions: 14,
                              value: _brightness.toDouble(),
                              onChanged: (v) => setState(() => _brightness = v.toInt()),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(_brightness.toString()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Send UDP Packet'),
                        onPressed: _sendUdp,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  void _openSettingsDialog() {
    final ipCtrl = TextEditingController(text: _ip);
    final portCtrl = TextEditingController(text: _port.toString());
    final gwCtrl = TextEditingController(text: _gateway);
    final subCtrl = TextEditingController(text: _subnet);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Settings'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'IP Address')),
                TextField(controller: portCtrl, decoration: const InputDecoration(labelText: 'UDP Port'), keyboardType: TextInputType.number),
                TextField(controller: gwCtrl, decoration: const InputDecoration(labelText: 'Gateway')),
                TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subnet Mask')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final ip = ipCtrl.text.trim();
                final port = int.tryParse(portCtrl.text.trim()) ?? 2000;
                final gw = gwCtrl.text.trim();
                final sub = subCtrl.text.trim();
                _saveSettings(ip, port, gw, sub);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
