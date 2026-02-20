import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> generateDoctorNumber(String doctorId) async {
    // Generate unique 8-character code
    final code = doctorId.substring(0, 8).toUpperCase();
    
    await _firestore.collection('doctors').doc(doctorId).update({
      'doctorNumber': code,
    });
    
    return code;
  }

  Future<ByteData?> generateQRImage(String data, {double size = 200}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode;
      final painter = QrPainter.withQr(
        qr: qrCode!,
        color: const Color(0xFF000000),
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      painter.paint(canvas, Size(size, size));
      final picture = picRecorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData;
    }
    return null;
  }

  Future<void> saveQRCodeUrl(String doctorId, String url) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'qrCodeUrl': url,
    });
  }
}
