import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flight.dart';
import '../providers/flight_provider.dart';
import 'details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _airportController = TextEditingController(text: 'SBGR');
  final _formKey = GlobalKey<FormState>();
  FlightType _selectedType = FlightType.all;

  @override
  void dispose() {
    _airportController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<FlightProvider>().search(
      airport: _airportController.text,
      type: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Consulta de Voos'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Consumer<FlightProvider>(
            builder: (context, provider, child) => RefreshIndicator(
              onRefresh: () => provider.search(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Para onde vamos?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Consulte chegadas e partidas de um aeroporto.'),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _airportController,
                          enabled: !provider.isLoading,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            labelText: 'Código ICAO',
                            hintText: 'Ex.: SBGR',
                            prefixIcon: Icon(Icons.local_airport),
                            helperText: 'SBGR · SBSP · SBBR · SBCF',
                          ),
                          validator: (value) =>
                              RegExp(r'^[A-Za-z]{4}$')
                                  .hasMatch((value ?? '').trim())
                              ? null
                              : 'Informe 4 letras, como SBGR.',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<FlightType>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de voo',
                          ),
                          items: [
                            for (final type in FlightType.values)
                              DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                          ],
                          onChanged: provider.isLoading
                              ? null
                              : (type) => setState(() => _selectedType = type!),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: provider.isLoading ? null : _search,
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar voos'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (provider.isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 12),
                    const Center(child: Text('Buscando voos...')),
                  ] else if (provider.error != null) ...[
                    const Icon(Icons.cloud_off, size: 40),
                    const SizedBox(height: 12),
                    Text(provider.error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => provider.search(),
                      child: const Text('Tentar novamente'),
                    ),
                  ] else ...[
                    Text(
                      '${provider.airport} · ${provider.type.label} · ${provider.flights.length} voos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 24),
                    if (provider.flights.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.flight, size: 40),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum voo encontrado.',
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Tente outro aeroporto ou tipo de voo.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    for (final flight in provider.flights)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            flight.isArrival
                                ? Icons.flight_land
                                : Icons.flight_takeoff,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            flight.identification,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${flight.categoryLabel}\n'
                              '${flight.isArrival ? 'Origem' : 'Destino'}: ${flight.location ?? 'Não informado'}\n'
                              'Partida: ${flight.departure ?? 'Não informada'}\n'
                              'Chegada: ${flight.arrival ?? 'Não informada'}',
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsPage(
                                flight: flight,
                                airport: provider.result!.airport,
                                source: provider.result!.source,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (provider.result != null)
                      const Text(
                        'Fonte: FlightAware · Atualize puxando a lista para baixo.',
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
