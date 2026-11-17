import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Android integration tests use a separate application ID', () {
    final gradle = File('android/app/build.gradle').readAsStringSync();
    expect(gradle, contains('project.findProperty("target")'));
    expect(gradle, contains('flutterTarget.startsWith("integration_test/")'));
    expect(gradle, contains('flutterTarget.contains("/integration_test/")'));
    expect(gradle, contains('project.findProperty("primeIntegrationTest")'));
    expect(gradle, contains('applicationId = integrationTestBuild ?'));
    expect(gradle, contains('com.github.wgh136.venera.prime.integrationtest'));
  });

  test('release APK names belong to this app', () {
    final gradle = File('android/app/build.gradle').readAsStringSync();
    expect(
      gradle,
      contains(
        r'outputFileName = "venera-lean-${variant.versionName}-${abi}.apk"',
      ),
    );
    expect(
      gradle,
      contains(r'outputFileName = "venera-lean-${variant.versionName}.apk"'),
    );
  });

  test('runtime version matches pubspec version', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final pubspecVersion = (pubspec['version'] as String).split('+').first;
    final appSource = File('lib/foundation/app.dart').readAsStringSync();
    final runtimeVersion = RegExp(
      r'final version = "([^"]+)";',
    ).firstMatch(appSource)!.group(1);

    expect(runtimeVersion, pubspecVersion);

    final releaseNotes = File(
      'doc/release-$pubspecVersion.md',
    ).readAsLinesSync();
    expect(releaseNotes.first, '# Venera Prime $pubspecVersion');

    final aboutSource = File(
      'lib/pages/settings/about.dart',
    ).readAsStringSync();
    expect(aboutSource, contains(r'Text("V${App.version}"'));
  });

  test('release workflow signs, builds both platforms and publishes', () {
    final workflowFile = File('.github/workflows/release.yml');
    expect(workflowFile.existsSync(), isTrue);
    final source = workflowFile.readAsStringSync();
    final workflow = loadYaml(source);
    final jobs = workflow['jobs'] as YamlMap;

    expect(source, contains("tags: ['v*']"));
    expect(jobs.keys, containsAll(['checks', 'android', 'windows', 'publish']));
    for (final secret in [
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
    ]) {
      expect(source, contains(secret));
    }
    expect(source, contains('flutter build apk --release'));
    expect(source, contains('flutter build windows --release'));
    expect(source, contains('gh release create'));
    expect(source, contains('SHA256SUMS'));

    // The upstream six-platform bot pipeline and its identity gate are gone.
    final workflows =
        Directory('.github/workflows')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();
    expect(workflows, ['release.yml']);
    expect(File('tool/check_release_identity.py').existsSync(), isFalse);
    expect(File('alt_store.json').existsSync(), isFalse);
  });
}
