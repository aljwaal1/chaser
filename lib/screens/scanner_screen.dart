import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../widgets/ui.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'barcode_scanner');
  QRViewController? controller;
  StreamSubscription<Barcode>? subscription;
  bool done = false;
  bool showHelp = false;
  bool cameraReady = false;
  String? cameraErrorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void reassemble() {
    super.reassemble();
    // مهم مع Hot Reload، ولا يؤثر على APK النهائي.
    if (controller == null) return;
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = controller;
    if (c == null) return;
    if (state == AppLifecycleState.resumed) {
      c.resumeCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      c.pauseCamera();
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
      Navigator.pop(context, result.trim());
    }
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;
    setState(() {
      cameraReady = true;
      cameraErrorText = null;
    });

    subscription = qrController.scannedDataStream.listen((scanData) async {
      if (done) return;
      final value = scanData.code;
      if (value == null || value.trim().isEmpty) return;
      done = true;
      try {
        await qrController.pauseCamera();
      } catch (_) {}
      if (mounted) Navigator.pop(context, value.trim());
    }, onError: (Object error) {
      if (!mounted) return;
      setState(() {
        cameraErrorText = error.toString();
        cameraReady = false;
      });
    });
  }

  Future<void> retryCamera() async {
    setState(() => cameraErrorText = null);
    try {
      await controller?.resumeCamera();
      if (mounted) setState(() => cameraReady = true);
    } catch (e) {
      if (mounted) setState(() => cameraErrorText = e.toString());
    }
  }

  Widget cameraFallbackCard() {
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
                'هذا الإصدار يستخدم محرك مسح بديل للأجهزة القديمة.\nإذا بقيت المشكلة، استخدم الإدخال اليدوي مؤقتًا.\n${cameraErrorText ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: softText, fontWeight: FontWeight.w700, height: 1.6),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: manualInput,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('إدخال الباركود يدويًا'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: retryCamera,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    controller?.dispose();
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
          IconButton(onPressed: () => setState(() => showHelp = !showHelp), icon: const Icon(Icons.help_outline), tooltip: 'مساعدة'),
          IconButton(onPressed: manualInput, icon: const Icon(Icons.keyboard), tooltip: 'إدخال يدوي'),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            formatsAllowed: const [
              BarcodeFormat.ean13,
              BarcodeFormat.ean8,
              BarcodeFormat.upcA,
              BarcodeFormat.upcE,
              BarcodeFormat.code128,
              BarcodeFormat.code39,
              BarcodeFormat.code93,
              BarcodeFormat.itf,
              BarcodeFormat.codabar,
              BarcodeFormat.qrcode,
            ],
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 18,
              borderLength: 34,
              borderWidth: 8,
              cutOutWidth: 270,
              cutOutHeight: 180,
            ),
          ),
          if (cameraErrorText != null) cameraFallbackCard(),
          if (!cameraReady && cameraErrorText == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('جاري تشغيل الكاميرا...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
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
                      'نصائح: امسح الباركود في إضاءة جيدة، لا تقرّب الهاتف كثيرًا، واجعل الباركود داخل المربع الأبيض.',
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
                'محرك قديم متوافق',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
