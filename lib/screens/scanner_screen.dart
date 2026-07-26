import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../utils/barcode_utils.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  static const List<BarcodeFormat> _supportedFormats = <BarcodeFormat>[
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
    BarcodeFormat.qrCode,
    BarcodeFormat.dataMatrix,
  ];

  final ImagePicker _picker = ImagePicker();
  late final MobileScannerController _controller;

  bool _starting = false;
  bool _stopping = false;
  bool _processing = false;
  bool _fallbackBusy = false;
  bool _completed = false;
  String? _cameraMessage;
  String? _lastCode;
  DateTime? _lastScanAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 400,
      formats: _supportedFormats,
      returnImage: false,
      torchEnabled: false,
      autoZoom: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_safeStart());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_completed || _fallbackBusy) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_safeStart());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_safeStop());
        break;
    }
  }

  Future<void> _safeStart() async {
    if (!mounted ||
        _completed ||
        _fallbackBusy ||
        _starting ||
        _stopping ||
        _controller.value.isRunning ||
        _controller.value.isStarting) {
      return;
    }

    _starting = true;
    if (mounted) {
      setState(() => _cameraMessage = 'وجّه الكاميرا نحو الباركود داخل الإطار.');
    }

    try {
      await _controller.start();
      if (mounted) {
        setState(() => _cameraMessage = null);
      }
    } on MobileScannerException catch (error) {
      if (mounted) {
        setState(() => _cameraMessage = _friendlyCameraError(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraMessage =
              'تعذر تشغيل المسح المباشر. استخدم كاميرا النظام أو الإدخال اليدوي.';
        });
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _safeStop() async {
    if (_stopping) return;
    if (!_controller.value.isRunning && !_controller.value.isStarting) return;

    _stopping = true;
    try {
      await _controller.stop();
    } catch (_) {
      // لا نمنع المستخدم من استعمال الطريقة الاحتياطية بسبب خطأ إيقاف الكاميرا.
    } finally {
      _stopping = false;
    }
  }

  String _friendlyCameraError(MobileScannerException error) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      return 'تم رفض إذن الكاميرا. اسمح للتطبيق باستخدام الكاميرا من إعدادات الهاتف، أو استخدم الإدخال اليدوي.';
    }
    if (error.errorCode == MobileScannerErrorCode.unsupported) {
      return 'المسح المباشر غير مدعوم على هذا الجهاز. استخدم كاميرا النظام أو قارئ باركود خارجي.';
    }
    if (error.errorCode ==
        MobileScannerErrorCode.controllerAlreadyInitialized) {
      return 'الكاميرا تعمل بالفعل. أعد المحاولة بعد لحظة.';
    }
    return 'لم تعمل الكاميرا المباشرة على هذا الجهاز. جرّب إعادة التشغيل أو كاميرا النظام.';
  }

  String? _firstValue(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final value = normalizeBarcodeValue(barcode.rawValue);
      if (isUsableBarcodeValue(value)) return value;
    }
    return null;
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_processing || _completed || _fallbackBusy) return;

    final value = _firstValue(capture);
    if (value == null) return;

    final now = DateTime.now();
    if (_lastCode == value &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!).inMilliseconds < 1400) {
      return;
    }
    _lastCode = value;
    _lastScanAt = now;
    unawaited(_acceptBarcode(value));
  }

  Future<void> _acceptBarcode(String rawValue) async {
    final value = normalizeBarcodeValue(rawValue);
    if (_completed || !isUsableBarcodeValue(value)) return;

    _completed = true;
    if (mounted) setState(() => _processing = true);
    await _safeStop();
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);

    if (mounted) Navigator.pop(context, value);
  }

  Future<void> _scanWithSystemCamera() async {
    if (_fallbackBusy || _processing || _completed) return;

    await _safeStop();
    if (!mounted) return;
    setState(() {
      _fallbackBusy = true;
      _cameraMessage = 'سيتم فتح كاميرا الهاتف لالتقاط صورة واضحة للباركود.';
    });

    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2200,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted || _completed) return;
      if (photo == null) {
        setState(() => _cameraMessage = 'تم إلغاء التصوير.');
        return;
      }

      setState(() => _cameraMessage = 'جاري قراءة الباركود من الصورة...');
      final capture = await _controller.analyzeImage(
        photo.path,
        formats: _supportedFormats,
      );
      final value = capture == null ? null : _firstValue(capture);
      if (value != null) {
        await _acceptBarcode(value);
        return;
      }

      if (mounted) {
        setState(() {
          _cameraMessage =
              'لم يظهر باركود واضح في الصورة. قرّب الكاميرا، تجنب الانعكاس، ثم حاول مرة أخرى.';
        });
      }
    } on MobileScannerException catch (error) {
      if (mounted) setState(() => _cameraMessage = _friendlyCameraError(error));
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraMessage =
              'تعذر تحليل الصورة. استخدم المسح المباشر أو أدخل الرمز يدويًا.';
        });
      }
    } finally {
      if (photo != null) {
        try {
          await File(photo.path).delete();
        } catch (_) {
          // image_picker يحفظ الصورة مؤقتًا والنظام سينظفها لاحقًا إذا تعذر حذفها.
        }
      }
      if (mounted && !_completed) {
        setState(() => _fallbackBusy = false);
        unawaited(_safeStart());
      }
    }
  }

  Future<void> _manualInput() async {
    if (_processing || _completed) return;
    await _safeStop();
    if (!mounted) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إدخال باركود أو قارئ خارجي'),
          content: TextField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'امسح بالقارئ الخارجي أو اكتب الرمز',
              hintText: 'EAN / UPC / Code 128',
              prefixIcon: Icon(Icons.keyboard),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final normalized = normalizeBarcodeValue(value);
              if (isUsableBarcodeValue(normalized)) {
                Navigator.pop(dialogContext, normalized);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = normalizeBarcodeValue(controller.text);
                if (isUsableBarcodeValue(normalized)) {
                  Navigator.pop(dialogContext, normalized);
                }
              },
              child: const Text('اعتماد'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (!mounted || _completed) return;
    if (result != null && isUsableBarcodeValue(result)) {
      await _acceptBarcode(result);
    } else {
      unawaited(_safeStart());
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الفلاش غير متاح على هذا الجهاز.')),
        );
      }
    }
  }

  Widget _cameraError(BuildContext context, MobileScannerException error) {
    return ColoredBox(
      color: const Color(0xFF101827),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white, size: 58),
              const SizedBox(height: 16),
              Text(
                _friendlyCameraError(error),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _scanWithSystemCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة بكاميرا النظام'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _manualInput,
                icon: const Icon(Icons.keyboard),
                label: const Text('إدخال يدوي أو قارئ خارجي'),
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('مسح الباركود'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fallbackBusy ? null : _scanWithSystemCamera,
            tooltip: 'كاميرا النظام',
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
          IconButton(
            onPressed: _manualInput,
            tooltip: 'إدخال أو قارئ خارجي',
            icon: const Icon(Icons.keyboard),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scanWidth = math.min(constraints.maxWidth * 0.84, 390.0);
            final scanHeight = math.min(190.0, constraints.maxHeight * 0.32);
            final scanWindow = Rect.fromCenter(
              center: Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight * 0.43,
              ),
              width: scanWidth,
              height: scanHeight,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  fit: BoxFit.cover,
                  scanWindow: scanWindow,
                  scanWindowUpdateThreshold: 8,
                  tapToFocus: true,
                  useAppLifecycleState: false,
                  onDetect: _handleCapture,
                  errorBuilder: _cameraError,
                  placeholderBuilder: (_) => const ColoredBox(
                    color: Colors.black,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(scanWindow),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (context, state, _) {
                          final torchOn = state.torchState == TorchState.on;
                          return _RoundControl(
                            onPressed: _toggleTorch,
                            icon: torchOn ? Icons.flash_on : Icons.flash_off,
                            label: torchOn ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
                          );
                        },
                      ),
                      _RoundControl(
                        onPressed: _safeStart,
                        icon: Icons.refresh,
                        label: 'إعادة تشغيل الكاميرا',
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_processing || _fallbackBusy) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            _cameraMessage ??
                                'ضع الباركود داخل الإطار. تتم القراءة تلقائيًا دون التقاط صورة.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _fallbackBusy
                                      ? null
                                      : _scanWithSystemCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('كاميرا النظام'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                  ),
                                  onPressed: _manualInput,
                                  icon: const Icon(Icons.keyboard),
                                  label: const Text('يدوي / خارجي'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }
}

class _RoundControl extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _RoundControl({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.black.withOpacity(0.62),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          color: Colors.white,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect window;

  const _ScannerOverlayPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = RRect.fromRectAndRadius(window, const Radius.circular(24));
    final shadePath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      shadePath,
      Paint()..color = Colors.black.withOpacity(0.52),
    );
    canvas.drawRRect(
      cutout,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final lineY = window.center.dy;
    canvas.drawLine(
      Offset(window.left + 24, lineY),
      Offset(window.right - 24, lineY),
      Paint()
        ..color = const Color(0xFF46E6A7)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.window != window;
  }
}
