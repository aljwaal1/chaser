import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/ui.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool done = false;
  bool showHelp = false;
  bool isTorchOn = false;
  String? cameraMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _safeStart();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _safeStop();
        break;
    }
  }

  Future<void> _safeStart() async {
    try {
      await controller.start();
    } catch (e) {
      if (mounted) setState(() => cameraMessage = e.toString());
    }
  }

  Future<void> _safeStop() async {
    try {
      await controller.stop();
    } catch (_) {}
  }

  Future<void> manualInput() async {
    final code = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إدخال الباركود يدويًا'),
          content: TextField(
            controller: code,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: input('رقم الباركود', Icons.qr_code),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, code.text.trim()), child: const Text('اعتماد')),
          ],
        ),
      ),
    );
    code.dispose();
    if (result != null && result.trim().isNotEmpty && mounted) {
      done = true;
      await _safeStop();
      if (mounted) Navigator.pop(context, result.trim());
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      done = true;
      await _safeStop();
      if (mounted) Navigator.pop(context, value.trim());
      return;
    }
  }

  Future<void> toggleTorch() async {
    try {
      await controller.toggleTorch();
      if (mounted) setState(() => isTorchOn = !isTorchOn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تشغيل الفلاش: $e')),
        );
      }
    }
  }

  Future<void> switchCamera() async {
    try {
      await controller.switchCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تبديل الكاميرا: $e')),
        );
      }
    }
  }

  Widget _scannerOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 280,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 18), color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: manualInput, icon: const Icon(Icons.keyboard), tooltip: 'إدخال يدوي'),
          IconButton(onPressed: toggleTorch, icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off), tooltip: 'الفلاش'),
          IconButton(onPressed: switchCamera, icon: const Icon(Icons.cameraswitch), tooltip: 'تبديل الكاميرا'),
          IconButton(onPressed: () => setState(() => showHelp = !showHelp), icon: const Icon(Icons.help_outline), tooltip: 'مساعدة'),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
          ),
          _scannerOverlay(),
          if (cameraMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .70), borderRadius: BorderRadius.circular(16)),
                child: Text(
                  'ملاحظة الكاميرا: $cameraMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          Positioned(
            bottom: 36,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (showHelp)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .70), borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'هذه نسخة مخصصة للأجهزة الحديثة وتستخدم محرك mobile_scanner الحديث. ضع الباركود داخل الإطار الأبيض، ويمكنك استخدام الإدخال اليدوي عند الحاجة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.5),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: .60), borderRadius: BorderRadius.circular(16)),
                  child: const Text(
                    'وجّه الكاميرا نحو الباركود\nأو اضغط أيقونة لوحة المفاتيح للإدخال اليدوي',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(999)),
              child: const Text(
                'محرك حديث للأجهزة الحديثة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
