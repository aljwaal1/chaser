import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/ui.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // نفتح كاميرا النظام بعد فتح الصفحة مباشرة.
    // هذا أكثر ثباتًا من كاميرا داخلية مباشرة، خصوصًا عندما تفشل mobile_scanner.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) unawaited(scanBySystemCamera());
    });
  }

  Future<void> scanBySystemCamera() async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _message = 'سيتم فتح كاميرا الجهاز. صوّر الباركود بوضوح داخل الصورة.';
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted) return;

      if (photo == null) {
        setState(() {
          _busy = false;
          _message = 'تم إلغاء التصوير. يمكنك المحاولة مرة أخرى أو إدخال الباركود يدويًا.';
        });
        return;
      }

      setState(() => _message = 'جاري قراءة الباركود من الصورة...');

      final inputImage = InputImage.fromFilePath(photo.path);
      final barcodeScanner = BarcodeScanner();
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      String? value;
      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.trim().isNotEmpty) {
          value = raw.trim();
          break;
        }
      }

      if (!mounted) return;

      if (value != null) {
        Navigator.pop(context, value);
        return;
      }

      setState(() {
        _busy = false;
        _message = 'لم يتم العثور على باركود في الصورة. قرّب الكاميرا من الباركود وحاول مرة أخرى.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'تعذر تشغيل كاميرا النظام أو قراءة الباركود. السبب: $e';
      });
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
      Navigator.pop(context, result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: manualInput, icon: const Icon(Icons.keyboard), tooltip: 'إدخال يدوي'),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: card(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(colors: [primary, Color(0xFF60A5FA)]),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'مسح آمن بكاميرا النظام',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذه النسخة لا تستخدم mobile_scanner نهائيًا. تفتح كاميرا الهاتف نفسها ثم تقرأ الباركود من الصورة، وهذا أكثر ثباتًا على الأجهزة الحديثة التي تفشل معها الكاميرا الداخلية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: softText, fontWeight: FontWeight.w700, height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  if (_busy) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  if (_message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: darkText, fontWeight: FontWeight.w800, height: 1.5),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : scanBySystemCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('فتح كاميرا الجهاز وقراءة الباركود'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : manualInput,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('إدخال الباركود يدويًا'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'نصيحة: اجعل الباركود قريبًا وواضحًا، وتأكد من وجود إضاءة جيدة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: softText, fontWeight: FontWeight.w700, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
