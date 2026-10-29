enum FlightType {
  arrivals('chegadas', 'Chegadas'),
  departures('partidas', 'Partidas'),
  all('todos', 'Todos');

  const FlightType(this.value, this.label);
  final String value;
  final String label;
}

class Flight {
  const Flight({
    required this.identification,
    required this.category,
    this.aircraft,
    this.location,
    this.departure,
    this.arrival,
  });

  final String identification;
  final String category;
  final String? aircraft;
  final String? location;
  final String? departure;
  final String? arrival;

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
    identification: _requiredText(json, 'identificacao'),
    category: _requiredText(json, 'categoria'),
    aircraft: _optionalText(json, 'tipo_aeronave'),
    location: _optionalText(json, 'local'),
    departure: _optionalText(json, 'partida'),
    arrival: _optionalText(json, 'chegada'),
  );

  bool get isArrival => category == 'chegadas' || category == 'em_rota';

  String get categoryLabel => switch (category) {
    'chegadas' => 'Chegada',
    'partidas' => 'Partida',
    'em_rota' => 'Em rota',
    'partidas_programadas' => 'Partida programada',
    _ => category,
  };

  String originAt(String airport) =>
      isArrival ? location ?? 'Não informado' : airport;
  String destinationAt(String airport) =>
      isArrival ? airport : location ?? 'Não informado';
}

class FlightSearchResult {
  const FlightSearchResult({
    required this.airport,
    required this.type,
    required this.source,
    required this.flights,
  });

  final String airport;
  final String type;
  final String source;
  final List<Flight> flights;

  factory FlightSearchResult.fromJson(Map<String, dynamic> json) {
    final items = json['voos'];
    if (items is! List) {
      throw const FormatException('A resposta não contém uma lista de voos.');
    }
    return FlightSearchResult(
      airport: _requiredText(json, 'aeroporto'),
      type: _requiredText(json, 'tipo_busca'),
      source: _requiredText(json, 'fonte'),
      flights: List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Voo em formato inválido.');
          }
          return Flight.fromJson(item);
        }),
      ),
    );
  }
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = _optionalText(json, key);
  if (value == null) throw FormatException('Campo obrigatório ausente: $key.');
  return value;
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Campo inválido: $key.');
  return value.trim().isEmpty ? null : value.trim();
}
