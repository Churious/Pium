import 'package:geolocator/geolocator.dart';
import 'package:pium/utils/user_messages.dart';

enum LocationFailureAction { openLocationSettings, openAppSettings }

class LocationResult {
  const LocationResult.success(this.latitude, this.longitude)
      : message = null,
        action = null;

  const LocationResult.failure(this.message, {this.action})
      : latitude = null,
        longitude = null;

  final double? latitude;
  final double? longitude;
  final String? message;
  final LocationFailureAction? action;

  bool get isSuccess => latitude != null && longitude != null;
}

class LocationService {
  Future<LocationResult> getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        UserMessages.locationPermissionOff,
        action: LocationFailureAction.openAppSettings,
      );
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult.failure(
        UserMessages.locationPermissionNeeded,
        action: LocationFailureAction.openAppSettings,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.failure(
        UserMessages.locationServiceOff,
        action: LocationFailureAction.openLocationSettings,
      );
    }

    // 최근 위치가 있으면 GPS 대기 없이 바로 사용 (체감 속도 개선)
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null) {
      final age = DateTime.now().difference(cached.timestamp);
      if (age.inMinutes < 15) {
        return LocationResult.success(cached.latitude, cached.longitude);
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult.success(position.latitude, position.longitude);
    } catch (_) {
      if (cached != null) {
        return LocationResult.success(cached.latitude, cached.longitude);
      }
      return const LocationResult.failure(UserMessages.locationUnavailable);
    }
  }

  Future<bool> openSuggestedSettings(LocationFailureAction action) {
    switch (action) {
      case LocationFailureAction.openLocationSettings:
        return Geolocator.openLocationSettings();
      case LocationFailureAction.openAppSettings:
        return Geolocator.openAppSettings();
    }
  }
}
