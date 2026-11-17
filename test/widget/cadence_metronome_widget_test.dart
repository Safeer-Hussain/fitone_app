import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/presentation/gps_running/stores/gps_running_store.dart';
import 'package:fitone/presentation/gps_running/views/gps_running_view.dart';
import 'package:fitone/presentation/gps_running/widgets/cadence_metronome_sheet.dart';
import 'package:fitone/presentation/gps_running/widgets/running_metrics_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockRunningRepository implements RunningRepository {
  final List<RunRecord> runs;
  _MockRunningRepository(this.runs);

  @override
  Future<void> saveRunRecord(RunRecord record) async => runs.add(record);

  @override
  Future<List<RunRecord>> getRunHistory() async => runs;

  @override
  Future<RunRecord?> getRunById(String id) async =>
      runs.where((r) => r.id == id).firstOrNull;
}

class _MockRingRepository implements RingRepository {
  @override
  Stream<RingTelemetry> watchTelemetry() => const Stream.empty();
  @override
  Future<List<RingDevice>> getDiscoveredDevices() async => [];
  @override
  Future<void> connectRing(String deviceId, String sdkType) async {}
  @override
  Future<void> disconnectRing() async {}
  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() async =>
      const HardwareDiagnostics(
        opticalPPG: 'OK',
        temperatureSensor: 'OK',
        sixAxisIMU: 'OK',
        bleTransceiver: 'OK',
        internalNAND: 'OK',
        batteryHealth: '100%',
      );
  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}
  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [];
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  int contentLength = 0;
  @override
  bool bufferOutput = true;
  @override
  Encoding encoding = utf8;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async => stream.drain();
  @override
  Future flush() async {}
  @override
  Future<HttpClientResponse> get done =>
      Future.value(_FakeHttpClientResponse());
  @override
  void write(Object? object) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? object = ""]) {}

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final List<int> _transparentPng = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPng.length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  String get reasonPhrase => 'OK';
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  late GpsRunningStore store;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    sl.registerLazySingleton<RunningRepository>(
      () => _MockRunningRepository([]),
    );
    sl.registerLazySingleton<RingRepository>(() => _MockRingRepository());
    sl.registerLazySingleton<GpsRunningStore>(
      () => GpsRunningStore(
        runningRepository: sl<RunningRepository>(),
        ringRepository: sl<RingRepository>(),
      ),
    );
    store = sl<GpsRunningStore>();
  });

  tearDown(() async {
    store.dispose();
    await sl.reset();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  void setupPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('CadenceMetronomeSheet Widget Tests', () {
    testWidgets('Renders sheet with 175 SPM, presets, slider, and switches', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        buildTestApp(CadenceMetronomeSheet(store: store)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audio & Visual Cadence Metronome'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cadence_spm_display_text')),
        findsOneWidget,
      );
      expect(find.text('175'), findsOneWidget);
      expect(find.byKey(const ValueKey('cadence_zone_badge')), findsOneWidget);
      expect(find.text('Optimal Race Pace'), findsOneWidget);

      expect(find.byKey(const ValueKey('chip_spm_160')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip_spm_175')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip_spm_180')), findsOneWidget);
      expect(find.byKey(const ValueKey('cadence_spm_slider')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('switch_metronome_audio')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('switch_metronome_haptic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('btn_toggle_metronome')),
        findsOneWidget,
      );
      expect(find.text('Start Cadence Metronome'), findsOneWidget);
    });

    testWidgets(
      'Tapping preset ChoiceChip updates SPM to 180 and alters zone',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          buildTestApp(CadenceMetronomeSheet(store: store)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('chip_spm_180')));
        await tester.pumpAndSettle();

        expect(store.cadenceSpm, equals(180));
        expect(find.text('180'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Start Cadence Metronome button starts metronome in store',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          buildTestApp(CadenceMetronomeSheet(store: store)),
        );
        await tester.pumpAndSettle();

        expect(store.isMetronomeEnabled, isFalse);
        final btnFinder = find.byKey(const ValueKey('btn_toggle_metronome'));
        await tester.ensureVisible(btnFinder);
        await tester.tap(btnFinder);
        await tester.pumpAndSettle();

        expect(store.isMetronomeEnabled, isTrue);
        expect(find.text('Stop Cadence Metronome'), findsOneWidget);

        await tester.tap(btnFinder);
        await tester.pumpAndSettle();

        expect(store.isMetronomeEnabled, isFalse);
        expect(find.text('Start Cadence Metronome'), findsOneWidget);
      },
    );

    testWidgets('Toggling audio and haptic switches updates store values', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        buildTestApp(CadenceMetronomeSheet(store: store)),
      );
      await tester.pumpAndSettle();

      expect(store.metronomeAudioEnabled, isTrue);
      final audioSwitchFinder = find.byKey(
        const ValueKey('switch_metronome_audio'),
      );
      await tester.ensureVisible(audioSwitchFinder);
      await tester.tap(audioSwitchFinder);
      await tester.pumpAndSettle();
      expect(store.metronomeAudioEnabled, isFalse);

      expect(store.metronomeHapticEnabled, isTrue);
      final hapticSwitchFinder = find.byKey(
        const ValueKey('switch_metronome_haptic'),
      );
      await tester.ensureVisible(hapticSwitchFinder);
      await tester.tap(hapticSwitchFinder);
      await tester.pumpAndSettle();
      expect(store.metronomeHapticEnabled, isFalse);
    });

    testWidgets(
      'CadenceMetronomeSheet renders without RenderFlex overflow in 800x360 landscape',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestApp(CadenceMetronomeSheet(store: store)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Audio & Visual Cadence Metronome'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('btn_toggle_metronome')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group(
    'RunningMetricsOverlay & GpsRunningView Metronome Integration Tests',
    () {
      testWidgets(
        'RunningMetricsOverlay contains cadence chip and opens sheet on tap',
        (tester) async {
          setupPortrait(tester);

          await tester.pumpWidget(
            buildTestApp(RunningMetricsOverlay(store: store)),
          );
          await tester.pumpAndSettle();

          final chipFinder = find.byKey(
            const ValueKey('cadence_metronome_overlay_chip'),
          );
          expect(chipFinder, findsOneWidget);
          expect(find.text('CADENCE'), findsOneWidget);

          await tester.tap(chipFinder);
          await tester.pumpAndSettle();

          expect(find.text('Audio & Visual Cadence Metronome'), findsOneWidget);
        },
      );

      testWidgets(
        'GpsRunningView AppBar contains cadence metronome action button',
        (tester) async {
          setupPortrait(tester);

          await tester.pumpWidget(buildTestApp(const GpsRunningView()));
          await tester.pumpAndSettle();

          final btnFinder = find.byKey(
            const ValueKey('gps_cadence_metronome_appbar_button'),
          );
          expect(btnFinder, findsOneWidget);

          await tester.tap(btnFinder);
          await tester.pumpAndSettle();

          expect(find.text('Audio & Visual Cadence Metronome'), findsOneWidget);
        },
      );
    },
  );
}
