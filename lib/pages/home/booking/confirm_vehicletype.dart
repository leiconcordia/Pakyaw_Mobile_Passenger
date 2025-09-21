import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pakyaw/assistants/request_assistant.dart';
import 'package:pakyaw/pages/home/booking/confirm_trip_page.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/trip_provider.dart';
import 'package:pakyaw/providers/vehicle_types_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../../shared/global_var.dart';

class ConfirmVehicletype extends ConsumerStatefulWidget {
  const ConfirmVehicletype({super.key});

  @override
  ConsumerState<ConfirmVehicletype> createState() => _ConfirmVehicletypeState();
}

class _ConfirmVehicletypeState extends ConsumerState<ConfirmVehicletype> {
  DatabaseService database = DatabaseService();
  int? selectedCapacity = 1;
  int? selectedIndex;
  String? selectedVehicle;
  int? baseRate;
  double? ratePerKm;
  String? typeImage;
  List<LatLng>? routePoints;
  String? duration;
  double? distance;
  int? wheels;
  String errorMessage = '';
  String id = '';

  @override
  void initState() {
    super.initState();
    ref.read(tripProvider.notifier).printTripDetails();
    final user = ref.read(authStateProvider).value;
    id = user!.uid;
  }

  /// Show warning dialog
  void showWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 50),
        content: const Text(
          'Please select a vehicle type before confirming.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Google Directions API
  Future<void> getRouteInfo(LatLng origin, LatLng destination, String travelMode) async {
    const String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': googleMapKey,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
    };
    Map<String, dynamic> body = {
      'origin': {
        'location': {
          'latLng': {'latitude': origin.latitude, 'longitude': origin.longitude}
        }
      },
      'destination': {
        'location': {
          'latLng': {'latitude': destination.latitude, 'longitude': destination.longitude}
        }
      },
      'travelMode': travelMode,
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'languageCode': 'en-US',
      'units': 'METRIC'
    };

    var response = await RequestAssistant.postRequest(url, headers, body);

    if (response is Map<String, dynamic> && response.containsKey('routes')) {
      final route = response['routes'][0];
      distance = route['distanceMeters'] / 1000.0;
      duration = route['duration'];
      routePoints = decodePolyline(route['polyline']['encodedPolyline']);
    } else {
      throw Exception('Failed to get route information: $response');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<PointLatLng> points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = ref.watch(vehicleTypesProvider);
    final maxCapacity = ref.watch(maxCapacityProvider);
    final trip = ref.watch(tripProvider);

    return vehicleTypes.when(
      data: (data) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              'Choose Vehicle',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
          ),

          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'How many are riding?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Passenger Capacity Dropdown
                maxCapacity.when(
                  data: (max) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: selectedCapacity,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onChanged: (value) {
                          setState(() => selectedCapacity = value);
                        },
                        items: List<int>.generate(max.capacity, (index) => index + 1)
                            .map((val) => DropdownMenuItem<int>(
                          value: val,
                          child: Text('For $val Passenger${val > 1 ? "s" : ""}'),
                        ))
                            .toList(),
                      ),
                    );
                  },
                  error: (e, _) => Text('Error: $e'),
                  loading: () => const Loading(),
                ),

                const SizedBox(height: 24),

                // Vehicle Types Grid
                const Text(
                  'Select Vehicle Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final vehicle = data[index];
                      final isAvailable = selectedCapacity! <= vehicle.capacity;
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: isAvailable
                            ? () {
                          setState(() {
                            selectedIndex = index;
                            selectedVehicle = vehicle.type;
                            baseRate = vehicle.baseRate;
                            ratePerKm = vehicle.ratePerKm;
                            typeImage = vehicle.image;
                            wheels = vehicle.wheels;
                          });
                        }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? (isSelected ? Colors.deepPurple.shade50 : Colors.white)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : (isAvailable ? Colors.grey.shade300 : Colors.grey.shade400),
                              width: 2,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                vehicle.image,
                                height: 50,
                                width: 50,
                                fit: BoxFit.contain,
                                color: isAvailable ? null : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                vehicle.type,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (selectedVehicle == null) {
                  showWarning();
                  return;
                }

                double vatTax = await database.getVatTax();
                double ccTax = await database.getCCTax();
                double baseKm = await database.getBaseKm();
                double charge = await database.getPassengerCharge(id);

                final tripData = ref.read(tripProvider);

                // Calculate route and fare
                if (wheels! <= 3) {
                  await getRouteInfo(
                    LatLng(tripData.pickupLoc!.latitude, tripData.pickupLoc!.longitude),
                    LatLng(tripData.dropOffLoc!.latitude, tripData.dropOffLoc!.longitude),
                    'TWO_WHEELER',
                  );
                } else {
                  await getRouteInfo(
                    LatLng(tripData.pickupLoc!.latitude, tripData.pickupLoc!.longitude),
                    LatLng(tripData.dropOffLoc!.latitude, tripData.dropOffLoc!.longitude),
                    'DRIVE',
                  );
                }

                double fare = (distance! < baseKm)
                    ? baseRate!.toDouble()
                    : baseRate! + ((distance! - 1) * ratePerKm!);

                ref.read(tripProvider.notifier).updateTrip(
                      (trip) => trip.copyWith(
                    vehicleType: selectedVehicle,
                    baseRate: baseRate,
                    ratePerKm: ratePerKm,
                    vehicleTypeImage: typeImage,
                    duration: duration,
                    route: routePoints,
                    distance: distance,
                    vatTax: vatTax,
                    ccTax: ccTax,
                    fare: double.parse((fare + charge).toStringAsFixed(2)),
                  ),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfirmTripPage()),
                );
              },
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
      error: (e, stack) => ErrorCatch(error: e.toString()),
      loading: () => const Loading(),
    );
  }
}
