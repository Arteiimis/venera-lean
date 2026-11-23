import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/pages/webview.dart';
import 'package:venera/utils/translations.dart';

/// Stands in for the WebView2 user data folder: creating one is a native
/// call, so the test only records that the Windows branch asked for it.
class _WebViewEnvironment extends PlatformWebViewEnvironment {
  _WebViewEnvironment(super.params) : super.implementation();

  int creations = 0;

  @override
  Future<PlatformWebViewEnvironment> create({
    WebViewEnvironmentSettings? settings,
  }) async {
    creations++;
    return this;
  }
}

class _WebViewPlatform extends InAppWebViewPlatform {
  _WebViewPlatform({required this.isAndroid});

  final bool isAndroid;
  int featureChecks = 0;
  _WebViewEnvironment? environment;

  @override
  PlatformWebViewEnvironment createPlatformWebViewEnvironmentStatic() =>
      environment ??= _WebViewEnvironment(
        const PlatformWebViewEnvironmentCreationParams(),
      );

  @override
  PlatformWebViewFeature createPlatformWebViewFeatureStatic() {
    featureChecks++;
    if (isAndroid) return _UnsupportedProxyFeature();
    return super.createPlatformWebViewFeatureStatic();
  }

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _WebView(params);
}

class _UnsupportedProxyFeature extends PlatformWebViewFeature {
  _UnsupportedProxyFeature()
    : super.implementation(const PlatformWebViewFeatureCreationParams());

  @override
  Future<bool> isFeatureSupported(WebViewFeature feature) async {
    expect(feature, WebViewFeature.PROXY_OVERRIDE);
    return false;
  }
}

class _WebView extends PlatformInAppWebViewWidget {
  _WebView(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: Key('native-webview'));

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTranslation.init);

  // The Windows branch builds the WebView2 user data folder from this path;
  // the platform stub never touches the disk.
  late Directory dataDir;
  setUpAll(() async {
    dataDir = await Directory.systemTemp.createTemp('webview-platform-');
    App.dataPath = dataDir.path;
  });
  tearDownAll(() => dataDir.delete(recursive: true));

  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.android,
  ]) {
    for (final proxy in ['system', 'direct', '127.0.0.1:8080']) {
      testWidgets('$platform with $proxy gates Android feature API', (
        tester,
      ) async {
        final originalPlatform = InAppWebViewPlatform.instance;
        final originalProxy = appdata.settings['proxy'];
        final backend = _WebViewPlatform(
          isAndroid: platform == TargetPlatform.android,
        );
        InAppWebViewPlatform.instance = backend;
        debugDefaultTargetPlatformOverride = platform;
        appdata.settings['proxy'] = proxy;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          if (originalPlatform != null) {
            InAppWebViewPlatform.instance = originalPlatform;
          }
          appdata.settings['proxy'] = originalProxy;
        });
        try {
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: App.rootNavigatorKey,
              home: const AppWebview(initialUrl: 'https://example.com/login'),
            ),
          );
          // The loading indicator animates until the native view loads; do not
          // pumpAndSettle against this deliberately inert native-view stub.
          // Two frames: the environment future completes between them.
          await tester.pump();
          await tester.pump();
          expect(
            backend.featureChecks,
            platform == TargetPlatform.android ? 1 : 0,
          );
          // Only the Windows target creates the WebView2 environment; the
          // check follows the target platform, so this holds on any host.
          expect(
            backend.environment?.creations ?? 0,
            platform == TargetPlatform.windows ? 1 : 0,
          );
          expect(find.byKey(const Key('native-webview')), findsOneWidget);
          expect(find.textContaining('UnimplementedError'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
