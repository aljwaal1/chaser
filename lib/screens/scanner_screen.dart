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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      // مهم جدًا: لا نترك المكتبة تشغّل الكاميرا تلقائيًا ثم نشغلها نحن مرة أخرى.
      // هذا كان يسبب genericError على بعض الأجهزة القديمة.
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      torchEnabled: false,
      returnImage: false,
    );

    // بعض الأجهزة القديمة تفتح شاشة سوداء إذا بدأنا الكاميرا مباشرة أثناء انتقال الشاشة.
    // التأخير القصير يعطي النظام وقتًا لإنهاء فتح الصفحة ثم تشغيل الكاميرا بثبات أكبر.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) await safeStartCamera();
    });
  }

  Future<void> safeStartCamera() async {
    if (_starting || _running || done || !mounted) return;
    _starting = true;
    try {
      await controller.start();
      _running = true;
    } catch (_) {
      _running = false;
      // سيظهر errorBuilder رسالة واضحة للمستخدم بدل الشاشة السوداء.
    } finally {
      _starting = false;
    }
  }

  Future<void> safeStopCamera() async {
    if (!_running && !_starting) return;
    try {
      await controller.stop();
    } catch (_) {
      // تجاهل الخطأ؛ الهدف فقط تحرير الكاميرا عند مغادرة الصفحة.
    } finally {
      _running = false;
      _starting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      safeStartCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      safeStopCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    safeStopCamera();
    controller.dispose();
    super.dispose();
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

  void onDetect(BarcodeCapture capture) {
    if (done) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    done = true;
    controller.stop().catchError((_) {});
    Navigator.pop(context, value.trim());
  }

  Widget cameraError(BuildContext context, MobileScannerException error, Widget? child) {
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
                'لم تعمل الكاميرا على هذا الجهاز.\nالسبب التقني: ${error.errorCode}',
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
                  onPressed: safeStartCamera,
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
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: onDetect,
            errorBuilder: cameraError,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 270,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
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
        ],
      ),
    );
  }
}
