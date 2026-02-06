import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'trips_view_model.dart';

class TripsListScreen extends ConsumerWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) =>
                  ref.read(tripsViewModelProvider.notifier).onQueryChanged(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by client, date, waybill, plate, route...',
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.trips.isEmpty
                    ? const Center(child: Text('No trips found yet. Import data first.'))
                    : ListView.builder(
                        itemCount: state.trips.length,
                        itemBuilder: (context, index) {
                          final trip = state.trips[index];
                          return ListTile(
                            title: Text('${trip.fromLocation} -> ${trip.toLocation}'),
                            subtitle: Text(
                              '${trip.clientName} • ${trip.plateNo} • ${trip.tripDate}',
                            ),
                            trailing: Text(
                              NumberFormat.currency(
                                symbol: 'SAR ',
                                decimalDigits: 0,
                              ).format(trip.tripAmount),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
