import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Windows frame-time baseline.
///
/// Runs the real engine in profile mode through `flutter drive` and prints one
/// `WIN_PERF {...}` JSON line per measured case. The companion script
/// `tool/test_performance_windows.ps1` collects those lines; compare two runs
/// (e.g. before and after a Flutter upgrade) instead of asserting wall-clock
/// thresholds here.
///
/// The cases use generated pixels and a local widget tree only; no app data,
/// settings or network access is touched.
///
/// `flutter drive` cannot attach to a Windows profile build reliably, so the
/// baseline script runs the profile binary directly and reads the samples this
/// test writes to `--dart-define=PERF_OUT=<path>` (plus stdout for debug runs).
const _perfOut = String.fromEnvironment('PERF_OUT');

void _emit(Map<String, Object?> sample) {
  final line = 'WIN_PERF ${const JsonEncoder().convert(sample)}';
  // ignore: avoid_print
  print(line);
  if (_perfOut.isEmpty) return;
  try {
    final file = File(_perfOut);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {
    // A missing output file must not fail the measurement run itself.
  }
}

void main() {
  final startedAt = DateTime.now();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final timings = <FrameTiming>[];
  SchedulerBinding.instance.addTimingsCallback(timings.addAll);

  void reset() => timings.clear();

  void report(String name, {int? startupMs, Map<String, Object?>? extra}) {
    final build = <int>[];
    final raster = <int>[];
    final total = <int>[];
    for (final timing in timings) {
      // Skip frames dominated by one-off pipeline/shader setup.
      if (timing.totalSpan.inMicroseconds > 500000) continue;
      build.add(timing.buildDuration.inMicroseconds);
      raster.add(timing.rasterDuration.inMicroseconds);
      total.add(timing.totalSpan.inMicroseconds);
    }
    build.sort();
    raster.sort();
    total.sort();
    int pick(List<int> values, double quantile) =>
        values.isEmpty ? -1 : values[((values.length - 1) * quantile).round()];
    _emit({
      'case': name,
      'frames': total.length,
      if (startupMs != null) 'startup_ms': startupMs,
      'build_p50_us': pick(build, 0.5),
      'build_p95_us': pick(build, 0.95),
      'raster_p50_us': pick(raster, 0.5),
      'raster_p95_us': pick(raster, 0.95),
      'total_p50_us': pick(total, 0.5),
      'total_p95_us': pick(total, 0.95),
      ...?extra,
    });
  }

  testWidgets('startup to first frame', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ListCase(count: 8)));
    await tester.pump(const Duration(milliseconds: 100));
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    report('startup_first_frame', startupMs: elapsed);
    reset();
  });

  testWidgets('list scroll', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ListCase(count: 400)));
    await tester.pumpAndSettle();
    reset();
    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(ListView), const Offset(0, -600), 3000);
      await tester.pumpAndSettle();
    }
    report('list_scroll', extra: {'rows': 400, 'flings': 3});
  });

  testWidgets('large image scroll', (tester) async {
    final images = await _largeImages(count: 8, width: 1400, height: 2000);
    await tester.pumpWidget(MaterialApp(home: _ImageCase(images: images)));
    await tester.pumpAndSettle();
    reset();
    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(ListView), const Offset(0, -700), 3000);
      await tester.pumpAndSettle();
    }
    report(
      'large_image_scroll',
      extra: {'images': images.length, 'width': 1400, 'height': 2000},
    );
    for (final image in images) {
      image.dispose();
    }
  });
}

Future<List<ui.Image>> _largeImages({
  required int count,
  required int width,
  required int height,
}) async {
  final pixels = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    final row = y * width * 4;
    for (var x = 0; x < width; x++) {
      final index = row + x * 4;
      final value = ((x * 7 + y * 13) & 0xff);
      pixels[index] = value;
      pixels[index + 1] = 0xff - value;
      pixels[index + 2] = (value * 3) & 0xff;
      pixels[index + 3] = 0xff;
    }
  }
  final completer = <ui.Image>[];
  for (var i = 0; i < count; i++) {
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    completer.add(frame.image);
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
  return completer;
}

class _ListCase extends StatelessWidget {
  const _ListCase({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SizedBox(
            height: 96 + (index % 4) * 18,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.primaries[index % Colors.primaries.length],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Row $index', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text('Subtitle text for row'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageCase extends StatelessWidget {
  const _ImageCase({required this.images});

  final List<ui.Image> images;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: images.length * 2,
      itemBuilder: (context, index) {
        final image = images[index % images.length];
        return AspectRatio(
          aspectRatio: image.width / image.height,
          child: RawImage(image: image, fit: BoxFit.cover),
        );
      },
    );
  }
}
