import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/explore_initialization_test.dart' as explore;
import '../test/support/data_sync_cases.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Isolated application only. These cases use temporary databases, fake comic
  // sources and a loopback WebDAV server, never the user's settings or library.
  group('Explore initialization', explore.main);
  group('WebDAV', () => registerDataSyncTransportTests(device: true));
}
