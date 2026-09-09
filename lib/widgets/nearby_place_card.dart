import 'package:flutter/material.dart';
import 'package:pium/models/nearby_place.dart';
import 'package:pium/services/map_launcher_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/date_format.dart';
import 'package:pium/utils/user_messages.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPlaceCard extends StatelessWidget {
  const NearbyPlaceCard({
    super.key,
    required this.place,
    this.mapLauncher = const MapLauncherService(),
  });

  final NearbyPlace place;
  final MapLauncherService mapLauncher;

  Future<void> _call(BuildContext context) async {
    if (!place.hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            UserMessages.noPhoneNumber,
            style: TextStyle(fontSize: 18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: place.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(BuildContext context) async {
    await mapLauncher.showDirectionsPicker(
      context,
      destination: MapDestination(
        name: place.name,
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon =
        place.isHospital ? Icons.local_hospital : Icons.local_pharmacy;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: PiumColors.navy, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: PiumColors.guideBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: PiumColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDistanceMeters(place.distanceMeters),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: PiumColors.tileTeal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.address,
                      style: const TextStyle(fontSize: 17, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _call(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: PiumColors.tileBlue,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.phone, size: 24),
                  label: const Text(
                    '전화하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openMap(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: PiumColors.navy,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.directions, size: 24),
                  label: const Text(
                    '길 안내',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
