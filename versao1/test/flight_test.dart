import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:voos_v1/models/flight.dart';
import 'package:voos_v1/providers/flight_provider.dart';
import 'package:voos_v1/services/flight_service.dart';

Map<String, Object?> payload({
  String airport = 'SBGR',
  List<Object?>? flights,
}) => {
  'aeroporto': airport,
  'tipo_busca': 'todos',
  'fonte': 'https://www.flightaware.com/live/airport/$airport',
  'total': flights?.length ?? 1,
  'voos':
      flights ??
      [
        {
          'identificacao': 'GLO1234',
          'categoria': 'em_rota',
          'tipo_aeronave': 'B738',
          'local': 'Brasília (SBBR)',
          'partida': '10:00',
          'chegada': null,
        },
      ],
};

http.Response jsonResponse(Object data, {int status = 200}) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'envia os filtros e interpreta o contrato real, UTF-8 e campos nulos',
    () async {
      final service = FlightService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/voos');
          expect(request.url.queryParameters, {
            'aeroporto': 'SBBR',
            'tipo': 'chegadas',
          });
          return jsonResponse(payload(airport: 'SBBR'));
        }),
      );
      addTearDown(service.dispose);
      final result = await service.fetchFlights(
        airport: 'SBBR',
        type: FlightType.arrivals,
      );
      expect(result.airport, 'SBBR');
      expect(result.flights.single.location, 'Brasília (SBBR)');
      expect(result.flights.single.arrival, isNull);
      expect(result.flights.single.categoryLabel, 'Em rota');
      expect(result.flights.single.originAt('SBBR'), 'Brasília (SBBR)');
    },
  );

  test('partidas programadas usam o aeroporto consultado como origem', () {
    const flight = Flight(
      identification: 'AZU9',
      category: 'partidas_programadas',
      location: 'Recife',
    );
    expect(flight.categoryLabel, 'Partida programada');
    expect(flight.originAt('SBGR'), 'SBGR');
    expect(flight.destinationAt('SBGR'), 'Recife');
  });

  test('lista vazia é uma resposta válida', () async {
    final service = FlightService(
      client: MockClient((_) async => jsonResponse(payload(flights: []))),
    );
    addTearDown(service.dispose);
    expect(
      (await service.fetchFlights(
        airport: 'SBGR',
        type: FlightType.all,
      )).flights,
      isEmpty,
    );
  });

  test('preserva a mensagem de erro da API', () async {
    final service = FlightService(
      client: MockClient(
        (_) async =>
            jsonResponse({'erro': 'FlightAware indisponível'}, status: 502),
      ),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchFlights(airport: 'SBGR', type: FlightType.all),
      throwsA(
        isA<FlightServiceException>().having(
          (error) => error.message,
          'mensagem',
          'FlightAware indisponível',
        ),
      ),
    );
  });

  test('trata erro HTTP com corpo HTML', () async {
    final service = FlightService(
      client: MockClient(
        (_) async => http.Response('<html>Erro interno</html>', 500),
      ),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchFlights(airport: 'SBGR', type: FlightType.all),
      throwsA(
        isA<FlightServiceException>().having(
          (error) => error.message,
          'mensagem',
          contains('500'),
        ),
      ),
    );
  });

  for (final body in [
    'não é JSON',
    '[]',
    '{"voos": {}}',
    '{"aeroporto":"SBGR","tipo_busca":"todos","fonte":"teste","voos":[42]}',
    '{"aeroporto":"SBGR","tipo_busca":"todos","fonte":"teste","voos":[{"identificacao":42}]}',
  ]) {
    test('rejeita resposta inválida: $body', () async {
      final service = FlightService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.fetchFlights(airport: 'SBGR', type: FlightType.all),
        throwsA(isA<FlightServiceException>()),
      );
    });
  }

  test('informa falha de conexão', () async {
    final service = FlightService(
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchFlights(airport: 'SBGR', type: FlightType.all),
      throwsA(
        isA<FlightServiceException>().having(
          (error) => error.message,
          'mensagem',
          contains('Python'),
        ),
      ),
    );
  });

  test('informa timeout', () async {
    final service = FlightService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.fetchFlights(airport: 'SBGR', type: FlightType.all),
      throwsA(
        isA<FlightServiceException>().having(
          (error) => error.message,
          'mensagem',
          contains('demorou'),
        ),
      ),
    );
  });

  test('provider normaliza ICAO e notifica carregamento e resultado', () async {
    final response = Completer<http.Response>();
    final provider = FlightProvider(
      service: FlightService(
        client: MockClient((request) {
          expect(request.url.queryParameters['aeroporto'], 'SBBR');
          return response.future;
        }),
      ),
    );
    addTearDown(provider.dispose);
    var changes = 0;
    provider.addListener(() => changes++);
    final search = provider.search(airport: ' sbbr ');
    expect(provider.isLoading, isTrue);
    response.complete(jsonResponse(payload(airport: 'SBBR')));
    await search;
    expect(provider.isLoading, isFalse);
    expect(provider.airport, 'SBBR');
    expect(provider.flights, hasLength(1));
    expect(provider.error, isNull);
    expect(changes, 2);
  });

  test('provider valida ICAO antes de acessar a rede', () async {
    var calls = 0;
    final provider = FlightProvider(
      service: FlightService(
        client: MockClient((_) async {
          calls++;
          return jsonResponse(payload());
        }),
      ),
    );
    addTearDown(provider.dispose);
    await provider.search(airport: '12');
    expect(calls, 0);
    expect(provider.error, contains('ICAO'));
    expect(provider.isLoading, isFalse);
  });

  test('provider permite tentar novamente após falha', () async {
    var calls = 0;
    final provider = FlightProvider(
      service: FlightService(
        client: MockClient((_) async {
          if (calls++ == 0) throw http.ClientException('offline');
          return jsonResponse(payload());
        }),
      ),
    );
    addTearDown(provider.dispose);
    await provider.search();
    expect(provider.error, isNotNull);
    await provider.search();
    expect(provider.error, isNull);
    expect(provider.flights, hasLength(1));
  });

  test(
    'a busca mais recente prevalece sobre respostas fora de ordem',
    () async {
      final first = Completer<http.Response>();
      final second = Completer<http.Response>();
      final provider = FlightProvider(
        service: FlightService(
          client: MockClient(
            (request) => request.url.queryParameters['aeroporto'] == 'SBGR'
                ? first.future
                : second.future,
          ),
        ),
      );
      addTearDown(provider.dispose);
      final oldSearch = provider.search(airport: 'SBGR');
      final newSearch = provider.search(airport: 'SBSP');
      second.complete(jsonResponse(payload(airport: 'SBSP')));
      await newSearch;
      first.complete(jsonResponse(payload(airport: 'SBGR')));
      await oldSearch;
      expect(provider.result!.airport, 'SBSP');
      expect(provider.isLoading, isFalse);
    },
  );

  test('resposta após dispose não notifica listeners', () async {
    final response = Completer<http.Response>();
    final provider = FlightProvider(
      service: FlightService(client: MockClient((_) => response.future)),
    );
    final search = provider.search();
    provider.dispose();
    response.complete(jsonResponse(payload()));
    await search;
  });
}
