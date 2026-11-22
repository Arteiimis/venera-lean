import 'dart:async';
import 'dart:io';

import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:flutter_test/flutter_test.dart';

// Guards the quickjs-ng API surface the comic-source engine relies on: value
// round trips, exception propagation, the interrupt handler behind
// `FlutterQjs(timeout:)` and promise job dispatch. Needs the built native
// library on the search path, so it follows the PRIME_NATIVE_ZIP_TEST=1
// convention used by the other native-library tests.
void main() {
  final skip = Platform.environment['PRIME_NATIVE_ZIP_TEST'] != '1'
      ? 'Set PRIME_NATIVE_ZIP_TEST=1 with the built flutter_qjs library on the library search path.'
      : null;

  test('values and errors round trip through the JS engine', () {
    final qjs = FlutterQjs();
    addTearDown(() => qjs.port.close());
    expect(qjs.evaluate('1 + 1'), 2);
    expect(qjs.evaluate('Number.MAX_SAFE_INTEGER'), 9007199254740991);
    expect(qjs.evaluate('NaN'), isNaN);
    expect(qjs.evaluate('"str"'), 'str');
    expect(qjs.evaluate('[1, 2, 3]'), [1, 2, 3]);
    expect(qjs.evaluate('({a: 1, b: "x"})'), {'a': 1, 'b': 'x'});
    expect(qjs.evaluate('true'), true);
    expect(
      () => qjs.evaluate('throw new Error("boom")'),
      throwsA(isA<JSError>()),
    );
  }, skip: skip);

  test('the interrupt handler enforces the timeout and recovers', () {
    final qjs = FlutterQjs(timeout: 100);
    addTearDown(() => qjs.port.close());
    final stopwatch = Stopwatch()..start();
    Object? error;
    try {
      qjs.evaluate('while (true) {}');
    } catch (e) {
      error = e;
    }
    stopwatch.stop();
    expect(error, isNotNull);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    // The runtime must stay usable after an interrupt.
    expect(qjs.evaluate('2 * 3'), 6);
  }, skip: skip);

  test('promise jobs are dispatched', () async {
    final qjs = FlutterQjs();
    addTearDown(() => qjs.port.close());
    qjs.evaluate('globalThis.__result = 0;');
    qjs.evaluate(
      'Promise.resolve().then(() => { globalThis.__result = 42; });',
    );
    unawaited(qjs.dispatch());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(qjs.evaluate('globalThis.__result'), 42);
  }, skip: skip);
}
