import 'package:flutter/foundation.dart';

import '../models/flight.dart';
import '../services/flight_service.dart';

class FlightProvider extends ChangeNotifier {
  FlightProvider({FlightService? service})
    : _service = service ?? FlightService();

  final FlightService _service;
  FlightSearchResult? _result;
  String _airport = 'SBGR';
  FlightType _type = FlightType.all;
  bool _isLoading = false;
  String? _error;
  int _requestId = 0;
  bool _disposed = false;

  List<Flight> get flights => _result?.flights ?? const [];
  FlightSearchResult? get result => _result;
  String get airport => _airport;
  FlightType get type => _type;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> search({String? airport, FlightType? type}) async {
    if (_disposed) return;
    final requestId = ++_requestId;
    final code = (airport ?? _airport).trim().toUpperCase();
    _result = null;
    _error = null;
    if (!RegExp(r'^[A-Z]{4}$').hasMatch(code)) {
      _isLoading = false;
      _error = 'Informe um código ICAO de 4 letras, como SBGR.';
      notifyListeners();
      return;
    }

    _airport = code;
    _type = type ?? _type;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.fetchFlights(airport: code, type: _type);
      // Uma resposta antiga não deve substituir uma busca mais recente.
      if (!_disposed && requestId == _requestId) _result = result;
    } on FlightServiceException catch (error) {
      if (!_disposed && requestId == _requestId) _error = error.message;
    } finally {
      if (!_disposed && requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _service.dispose();
    super.dispose();
  }
}
