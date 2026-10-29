import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:voos_v1/main.dart';
import 'package:voos_v1/providers/flight_provider.dart';
import 'package:voos_v1/services/flight_service.dart';

http.Response flightsResponse({bool empty = false}) => http.Response(
  jsonEncode({
    'aeroporto': 'SBGR',
    'tipo_busca': 'todos',
    'fonte': 'https://www.flightaware.com/live/airport/SBGR',
    'total': empty ? 0 : 1,
    'voos': empty
        ? []
        : [
            {
              'identificacao': 'GLO1234',
              'categoria': 'chegadas',
              'tipo_aeronave': 'B738',
              'local': 'Brasília (SBBR)',
              'partida': '10:00',
              'chegada': null,
            },
          ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<FlightProvider> mountApp(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final provider = FlightProvider(
    service: FlightService(client: MockClient(handler)),
  );
  addTearDown(provider.dispose);
  unawaited(provider.search());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: provider, child: const FlightsApp()),
  );
  return provider;
}

Future<void> reveal(WidgetTester tester, Finder finder, double delta) =>
    tester.scrollUntilVisible(
      finder.hitTestable(),
      delta,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );

void main() {
  testWidgets('mostra carregamento e abre os detalhes em tela de celular', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await mountApp(tester, (_) => response.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(flightsResponse());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('GLO1234'), 250);
    await tester.tap(find.text('GLO1234'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do voo'), findsOneWidget);
    expect(find.text('GLO1234'), findsOneWidget);
    expect(find.text('Brasília (SBBR)'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do voo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro de conexão permite recuperar a lista', (tester) async {
    var calls = 0;
    await mountApp(tester, (_) async {
      if (calls++ == 0) throw http.ClientException('offline');
      return flightsResponse();
    });
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Tentar novamente'), 200);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('GLO1234'), 200);
    expect(find.text('GLO1234'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista vazia é apresentada sem erro', (tester) async {
    await mountApp(tester, (_) async => flightsResponse(empty: true));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Nenhum voo encontrado.'), 200);
    expect(find.text('Nenhum voo encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valida ICAO e envia nova busca e filtro para a API', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final provider = await mountApp(tester, (request) async {
      requests.add(request);
      return flightsResponse(empty: true);
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Buscar voos'));
    await tester.pumpAndSettle();
    expect(find.text('Informe 4 letras, como SBGR.'), findsOneWidget);
    expect(requests, hasLength(1));

    await tester.enterText(find.byType(TextFormField), ' sbsp ');
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partidas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar voos'));
    await tester.pumpAndSettle();
    expect(provider.airport, 'SBSP');
    expect(requests.last.url.queryParameters, {
      'aeroporto': 'SBSP',
      'tipo': 'partidas',
    });
    expect(tester.takeException(), isNull);
  });
}
