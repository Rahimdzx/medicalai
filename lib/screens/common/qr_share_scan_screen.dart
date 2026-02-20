import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/doctor_service.dart';
import '../doctor/doctor_profile_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
      Navigator.pop(context);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    
    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;
    
    if (code != null) {
      setState(() => _isScanning = false);
      
      final doctor = await DoctorService().getDoctorById(code);
      if (doctor != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor not found')),
        );
        setState(() => _isScanning = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: _onDetect,
        overlay: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(50),
        ),
      ),
    );
  }
}
