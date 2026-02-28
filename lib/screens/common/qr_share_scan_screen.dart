import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/doctor_service.dart';
import '../../models/doctor_model.dart';
import '../../l10n/app_localizations.dart';
import '../doctor_profile_screen.dart';

/// QR Code Scanner Screen for Patients
/// 
/// Features:
/// - Scan doctor QR codes
/// - Add doctors to patient's myDoctors list
/// - Show doctor information after scanning
class QrShareScanScreen extends StatefulWidget {
  const QrShareScanScreen({super.key});

  @override
  State<QrShareScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrShareScanScreen> {
  bool _isScanning = true;
  bool _isProcessing = false;
  bool _cameraReady = false;
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Check and request permission
    final status = await Permission.camera.request();
    
    if (!status.isGranted) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to scan QR codes')),
      );
      Navigator.pop(context);
      return;
    }

    // Initialize camera controller
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Small delay to ensure camera is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanning = false;
        _isProcessing = true;
      });

      await _processScannedCode(code);
    }
  }

  Future<void> _processScannedCode(String code) async {
    try {
      debugPrint('Scanned QR code: $code');

      String? doctorId;
      Map<String, dynamic>? qrData;

      // Try to parse as JSON first
      try {
        qrData = jsonDecode(code) as Map<String, dynamic>;
        doctorId = qrData['doctorId'] as String? ?? qrData['userId'] as String? ?? qrData['id'] as String?;
      } catch (e) {
        // Not JSON, treat as plain doctor ID
        doctorId = code.trim();
      }

      if (doctorId == null || doctorId.isEmpty) {
        _showError('Invalid QR code format');
        return;
      }

      // Get current user
      final auth = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final patientId = auth.user?.uid;

      if (patientId == null) {
        _showError('Please login to add doctors');
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Verify doctor exists and get their data
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!mounted) return;

      if (!doctorDoc.exists) {
        // Try users collection as fallback
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .get();

        if (!userDoc.exists) {
          Navigator.pop(context); // Close loading
          _showError('Doctor not found. Please check the QR code and try again.');
          return;
        }

        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData?['role'] != 'doctor') {
          Navigator.pop(context); // Close loading
          _showError('This QR code does not belong to a doctor.');
          return;
        }

        // Doctor exists in users collection, ensure they have a doctor profile
        await _addDoctorToPatient(patientId, doctorId, userData?['name'] ?? 'Unknown Doctor');
        Navigator.pop(context); // Close loading
        
        // Create minimal doctor data and navigate
        final limitedDoctor = await _createLimitedDoctorData(doctorId);
        if (limitedDoctor != null && mounted) {
          _showSuccessAndNavigate(limitedDoctor);
        }
      } else {
        // Doctor found in doctors collection
        final doctorData = doctorDoc.data() as Map<String, dynamic>?;
        final doctorName = doctorData?['name'] ?? 'Unknown Doctor';
        
        await _addDoctorToPatient(patientId, doctorId, doctorName);
        Navigator.pop(context); // Close loading

        // Try to get full doctor data using DoctorService
        try {
          final doctor = await DoctorService().getDoctorById(doctorId);

          if (doctor != null && mounted) {
            _showSuccessAndNavigate(doctor);
          } else if (mounted) {
            // Doctor exists but full profile couldn't be loaded
            // Navigate with limited data from Firestore
            final limitedDoctor = await _createLimitedDoctorData(doctorId);
            if (limitedDoctor != null) {
              _showSuccessAndNavigate(limitedDoctor);
            } else {
              _showError('Doctor found but could not load profile. Please try again.');
            }
          }
        } catch (e) {
          debugPrint('Error loading doctor via service: $e');
          // Fallback to limited data
          if (mounted) {
            final limitedDoctor = await _createLimitedDoctorData(doctorId);
            if (limitedDoctor != null) {
              _showSuccessAndNavigate(limitedDoctor);
            } else {
              _showError('Doctor found but could not load profile. Please try again.');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      if (mounted) {
        // Close loading if showing
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      _showError('Error processing QR code: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _addDoctorToPatient(String patientId, String doctorId, String doctorName) async {
    try {
      // Add to patient's myDoctors array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .update({
        'myDoctors': FieldValue.arrayUnion([doctorId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also create a connection record
      await FirebaseFirestore.instance
          .collection('patient_doctors')
          .doc('${patientId}_$doctorId')
          .set({
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'connectedAt': FieldValue.serverTimestamp(),
        'connectedVia': 'qr_scan',
      }, SetOptions(merge: true));

      debugPrint('Doctor $doctorId added to patient $patientId');
    } catch (e) {
      debugPrint('Error adding doctor to patient: $e');
      // Don't throw - the doctor was found, just couldn't save the connection
    }
  }

  /// Creates a minimal doctor object from Firestore data when full model fails to load
  Future<DoctorModel?> _createLimitedDoctorData(String doctorId) async {
    try {
      // Try to get doctor data from doctors collection
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      
      if (doctorDoc.exists) {
        return DoctorModel.fromFirestore(doctorDoc);
      }
      
      // Fallback to users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        // Create a minimal doctor model from user data
        return DoctorModel(
          id: doctorId,
          userId: doctorId,
          name: data['name'] ?? 'Unknown Doctor',
          nameEn: data['name'] ?? 'Unknown Doctor',
          nameAr: data['nameAr'] ?? data['name'] ?? 'Unknown Doctor',
          specialty: data['specialty'] ?? 'General',
          specialtyEn: data['specialty'] ?? 'General',
          specialtyAr: data['specialtyAr'] ?? data['specialty'] ?? 'General',
          price: (data['price'] ?? 50).toDouble(),
          currency: data['currency'] ?? 'RUB',
          rating: (data['rating'] ?? 5.0).toDouble(),
          doctorNumber: data['doctorNumber'] ?? doctorId.substring(0, 8).toUpperCase(),
          description: data['about'] ?? data['description'] ?? data['bio'] ?? '',
          isActive: data['isActive'] ?? true,
          allowedFileTypes: const ['image', 'pdf'],
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating limited doctor data: $e');
      return null;
    }
  }

  void _showSuccessAndNavigate(dynamic doctor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Doctor Added!'),
        content: Text('Dr. ${doctor.name} has been added to your doctors list.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
              );
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanDoctorCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              _cameraController?.toggleTorch();
            },
          ),
        ],
      ),
      body: !_cameraReady
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            )
          : Stack(
              children: [
          // Camera Preview
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          
          // Scan overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          
          // Scan frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner markers
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerMarker(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 1.5708,
                      child: _buildCornerMarker(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 3.14159,
                      child: _buildCornerMarker(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.rotate(
                      angle: 4.71239,
                      child: _buildCornerMarker(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  l10n.pointCameraToQR,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.green, width: 4),
          left: BorderSide(color: Colors.green, width: 4),
        ),
      ),
    );
  }
}
