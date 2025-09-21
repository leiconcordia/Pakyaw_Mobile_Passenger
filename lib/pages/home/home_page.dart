import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pakyaw/pages/home/booking/map.dart';
import 'package:pakyaw/pages/home/vehicle_options.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/promo_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/global_var.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../models/promo_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware, WidgetsBindingObserver {
  String id = '';
  String vehicleTypeSelected = 'Vehicle';
  final Telephony telephony = Telephony.instance;

  void changeSelectedVehicle(value) {
    setState(() => vehicleTypeSelected = value);
  }

  void showVehicleOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
          child: VehicleOptions(
            vehicletype: changeSelectedVehicle,
          ),
        );
      },
    );
  }

  Future<void> resetCancellations() async {
    DatabaseService database = DatabaseService();
    await database.resetCancellations(id);
  }

  Future<void> updateSubmittedIDS(String userId) async {
    DatabaseService database = DatabaseService();
    database.updateSubmittedID(userId);
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    id = user!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetCancellations();
    });
    updateSubmittedIDS(id);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final promos = ref.watch(allPromoProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Text(
                'Pakyaw',
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF83358E), // Primary color
                ),
              ),
            ),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DropOffSelect())),
                child: Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 26),
                      const SizedBox(width: 12),
                      Text(
                        'Where to?',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // PROMO SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Promos',
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 6,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 180, // Fixed height for promo area
              child: promos.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text('No promos available'));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return PromoTileHomePage(promoModel: data[index]);
                    },
                  );
                },
                error: (e, stack) => ErrorCatch(error: e.toString()),
                loading: () => const Loading(),
              ),
            ),


          ],
        ),
      ),
    );
  }
}


//PROMO WIDGET
class PromoTileHomePage extends StatelessWidget {
  final PromoModel promoModel;
  const PromoTileHomePage({super.key, required this.promoModel});

  @override
  Widget build(BuildContext context) {
    DateTime startingDate = promoModel.startDate.toDate();
    DateTime endingDate = promoModel.endDate.toDate();
    String formattedStartDate = DateFormat('MM/dd/yyyy').format(startingDate);
    String formattedEndDate = DateFormat('MM/dd/yyyy').format(endingDate);

    return Container(
      width: 150, // ⬅️ Small square-like box
      height: 50,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Banner at the top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              promoModel.banner,
              height: 80, // ⬅️ smaller image
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 6),

          // 🔹 Promo name and discount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  promoModel.promoName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF83358E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(promoModel.discount * 100).toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 🔹 Validity dates
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$formattedStartDate - $formattedEndDate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

