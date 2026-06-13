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
  late final MobileScannerController controller;

  bool done = false;
  bool showHelp = false;
  bool _starting = false;
  bool _running = false;
  bool _torchOn = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // نسخة مستقرة للأجهزة الحديثة: mobile_scanner 5.2.3 أهدأ من 7.x على بعض الأجهزة.
    // autoStart=false حتى لا يتم تشغيل الكاميرا مرتين أثناء فتح الصفحة.
    controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      torchEnabled: false,
      returnImage: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) await safeStartCamera();
    });
  }

  Future<void> safeStartCamera() async {
    if (_starting || _running || done || !mounted) return;
    setState(() => _lastError = null);
    _starting = true;
    try {
      await controller.start();
      _running = true;
    } catch (e) {
      _running = false;
      if (mounted) setState(() => _lastError = e.toString());
    } finally {
      _starting = false;
    }
  }

  Future<void> safeStopCamera() async {
    if (!_running && !_starting) return;
    try {
      await controller.stop();
    } catch (_) {
      // تجاهل الخطأ؛ الهدف تحرير الكاميرا فقط.
    } finally {
      _running = false;
      _starting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(safeStartCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(safeStopCamera());
    }
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
      await safeStopCamera();
      if (mounted) Navigator.pop(context, result.trim());
    }
  }

  void onDetect(BarcodeCapture capture) {
    if (done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      done = true;
      unawaited(safeStopCamera());
      Navigator.pop(context, value.trim());
      return;
    }
  }

  Future<void> toggleTorch() async {
    try {
      await controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
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

  Widget cameraError(BuildContext context, MobileScannerException error, Widget? child) {
    return _CameraFallback(
      message: 'لم تعمل الكاميرا على هذا الجهاز.\nالسبب التقني: ${error.errorCode}',
      onManual: manualInput,
      onRetry: safeStartCamera,
    );
  }

  Widget _overlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 280,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(safeStopCamera());
    controller.dispose();
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
          IconButton(onPressed: toggleTorch, icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off), tooltip: 'الفلاش'),
          IconButton(onPressed: switchCamera, icon: const Icon(Icons.cameraswitch), tooltip: 'تبديل الكاميرا'),
          IconButton(onPressed: () => setState(() => showHelp = !showHelp), icon: const Icon(Icons.help_outline), tooltip: 'مساعدة'),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: onDetect,
            errorBuilder: cameraError,
          ),
          _overlay(),
          if (_lastError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(.70), borderRadius: BorderRadius.circular(16)),
                child: Text(
                  'ملاحظة الكاميرا: $_lastError',
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
                    decoration: BoxDecoration(color: Colors.black.withOpacity(.70), borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'هذه نسخة مستقرة للأجهزة الحديثة. ضع الباركود داخل الإطار الأبيض. إذا لم تعمل الكاميرا استخدم الإدخال اليدوي أو قارئ باركود خارجي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.5),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.60), borderRadius: BorderRadius.circular(16)),
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
              decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(999)),
              child: const Text(
                'محرك مستقر للأجهزة الحديثة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({
    required this.message,
    required this.onManual,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onManual;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: card(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: danger, size: 56),
              const SizedBox(height: 12),
              const Text('تعذر تشغيل الكاميرا', style: TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: softText, fontWeight: FontWeight.w700, height: 1.6),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('إدخال الباركود يدويًا'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة محاولة تشغيل الكاميرا'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
