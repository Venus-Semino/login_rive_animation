import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:login_rive_animation/config/api_config.dart';
import 'package:login_rive_animation/services/api_service.dart';

class _User extends Fake implements User {
  final refreshes = <bool>[];
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    refreshes.add(forceRefresh);
    return forceRefresh ? 'refreshed-test-token' : 'initial-test-token';
  }
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.user);
  User? user;
  @override
  User? get currentUser => user;
}

const _fixture =
    '[{"gameId":1,"title":"Contrato de prueba","price":129.99,"consoleId":1,"stock":4,"category":"Puzles"}]';

void main() {
  test('Web uses browser host; Android emulator uses host alias', () {
    expect(
      ApiConfig.resolve(isWeb: true, platform: TargetPlatform.android),
      'http://localhost:8080',
    );
    expect(
      ApiConfig.resolve(isWeb: false, platform: TargetPlatform.android),
      'http://10.0.2.2:8080',
    );
    expect(
      ApiConfig.resolve(
        isWeb: false,
        platform: TargetPlatform.android,
        override: 'http://192.168.1.10:8080/',
      ),
      'http://192.168.1.10:8080',
    );
  });
  test('Reject credentials and malformed base URL', () {
    for (final invalid in [
      'relative/path',
      'ftp://host',
      'http://user:password@host',
      'http://host?token=secret',
    ]) {
      expect(
        () => ApiConfig.resolve(
          isWeb: true,
          platform: TargetPlatform.linux,
          override: invalid,
        ),
        throwsArgumentError,
      );
    }
  });
  test(
    'Uses /videogames and Firebase Bearer; decodes real DTO fields',
    () async {
      final user = _User();
      final api = ApiService(
        auth: _Auth(user),
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.url.path, '/videogames');
          expect(request.headers['Authorization'], 'Bearer initial-test-token');
          return http.Response(
            _fixture,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await api.obtenerProductos();
      expect(result.single.title, 'Contrato de prueba');
      expect(result.single.stock, 4);
      expect(result.single.category, 'Puzles');
      expect(result.single.price, 129.99);
      expect(user.refreshes, [false]);
    },
  );
  test('No user: no unauthenticated HTTP request', () async {
    var calls = 0;
    final api = ApiService(
      auth: _Auth(null),
      client: MockClient((request) async {
        calls++;
        return http.Response(_fixture, 200);
      }),
    );
    await expectLater(
      api.obtenerProductos(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(calls, 0);
  });
  test('401 refreshes Firebase token once and retries', () async {
    final user = _User();
    var calls = 0;
    final api = ApiService(
      auth: _Auth(user),
      client: MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('', 401);
        expect(request.headers['Authorization'], 'Bearer refreshed-test-token');
        return http.Response(_fixture, 200);
      }),
    );
    expect((await api.obtenerProductos()).length, 1);
    expect(calls, 2);
    expect(user.refreshes, [false, true]);
  });
  for (final status in [401, 403, 500]) {
    test('Controlled error for HTTP $status', () async {
      final api = ApiService(
        auth: _Auth(_User()),
        client: MockClient(
          (_) async => http.Response('private server details', status),
        ),
      );
      await expectLater(
        api.obtenerProductos(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', status)
              .having(
                (e) => e.message.contains('private'),
                'no server body leak',
                false,
              ),
        ),
      );
    });
  }
  test('Connection error is understandable', () async {
    final api = ApiService(
      auth: _Auth(_User()),
      client: MockClient(
        (_) async => throw http.ClientException('socket details'),
      ),
    );
    await expectLater(
      api.obtenerProductos(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No se pudo conectar'),
        ),
      ),
    );
  });
  for (final body in ['not json', '{}', '[{"name":"Wrong contract"}]']) {
    test('Reject malformed contract: $body', () async {
      final api = ApiService(
        auth: _Auth(_User()),
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(api.obtenerProductos(), throwsA(isA<ApiException>()));
    });
  }
  test('Empty catalog stays empty; no simulated games', () async {
    final api = ApiService(
      auth: _Auth(_User()),
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    expect(await api.obtenerProductos(), isEmpty);
  });
  test(
    'Absent stock/category are not replaced with invented zero/genre',
    () async {
      final api = ApiService(
        auth: _Auth(_User()),
        client: MockClient(
          (_) async => http.Response(
            '[{"gameId":1,"title":"Contrato","price":10}]',
            200,
          ),
        ),
      );
      final game = (await api.obtenerProductos()).single;
      expect(game.stock, isNull);
      expect(game.category, isNull);
    },
  );
}
