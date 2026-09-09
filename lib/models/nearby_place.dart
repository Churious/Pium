class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.placeUrl,
  });

  final String name;
  final String type;
  final int distanceMeters;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;
  final String? placeUrl;

  bool get isHospital => type == 'hospital';
  bool get isPharmacy => type == 'pharmacy';
  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      address: json['address'] as String? ?? '',
      phone: (json['phone'] as String?)?.trim(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      placeUrl: json['placeUrl'] as String?,
    );
  }
}
