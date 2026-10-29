import 'package:flutter/material.dart';

import '../models/flight.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({
    super.key,
    required this.flight,
    required this.airport,
    required this.source,
  });

  final Flight flight;
  final String airport;
  final String source;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes do voo')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                flight.isArrival ? Icons.flight_land : Icons.flight_takeoff,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                flight.identification,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    _InfoTile(label: 'Categoria', value: flight.categoryLabel),
                    _InfoTile(label: 'Aeroporto consultado', value: airport),
                    _InfoTile(label: 'Origem', value: flight.originAt(airport)),
                    _InfoTile(
                      label: 'Destino',
                      value: flight.destinationAt(airport),
                    ),
                    _InfoTile(label: 'Aeronave', value: flight.aircraft),
                    _InfoTile(label: 'Partida', value: flight.departure),
                    _InfoTile(label: 'Chegada', value: flight.arrival),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Fonte', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(source),
              const SizedBox(height: 16),
              const Text(
                'Os horários são exibidos conforme recebidos do painel de voos.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), subtitle: Text(value ?? 'Não informado'));
}
