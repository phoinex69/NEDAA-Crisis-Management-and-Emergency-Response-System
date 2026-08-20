import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';

import '../../controllers/map_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/map_offline_service.dart';
import '../widgets/nidaa_app_bar.dart';
import 'widgets/map_info_sheets.dart';
import 'widgets/map_marker_builder.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final fm.MapController _map = fm.MapController();
  final MapController _mapCtrl = Get.find<MapController>();

  @override
  void initState() {
    super.initState();
    _mapCtrl.loadMapData();
    _mapCtrl.startTracking();
  }

  @override
  void dispose() {
    _mapCtrl.stopTracking();
    super.dispose();
  }

  Future<void> _recenterToUser() async {
    if (_mapCtrl.userLocation.value == null) {
      await _mapCtrl.startTracking();
      if (_mapCtrl.userLocation.value == null) return;
    }
    _map.move(_mapCtrl.userLocation.value!, 15);
  }

  List<fm.Marker> _buildMarkers() {
    final markers = <fm.Marker>[];
    for (final zone in _mapCtrl.dangerZones) {
      markers.add(fm.Marker(
        point: zone.center,
        width: 64,
        height: 74,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showZoneInfoSheet(
            context,
            zone,
            nearestHospital: _mapCtrl.nearestHospitalTo(zone.center),
          ),
          child: MapMarkerBuilder.dangerMarker(),
        ),
      ));
    }
    for (final hospital in _mapCtrl.hospitals) {
      markers.add(fm.Marker(
        point: hospital.position,
        width: 64,
        height: 74,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showHospitalInfoSheet(context, hospital),
          child: MapMarkerBuilder.hospitalMarker(),
        ),
      ));
    }
    for (final center in _mapCtrl.serviceCenters) {
      markers.add(fm.Marker(
        point: center.position,
        width: 120,
        height: 40,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showServiceCenterInfoSheet(context, center),
          child: MapMarkerBuilder.serviceCenterMarker(center.name),
        ),
      ));
    }
    for (final shelter in _mapCtrl.shelters) {
      markers.add(fm.Marker(
        point: shelter.position,
        width: 64,
        height: 74,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showShelterInfoSheet(context, shelter),
          child: MapMarkerBuilder.shelterMarker(),
        ),
      ));
    }
    for (final point in _mapCtrl.safePoints) {
      markers.add(fm.Marker(
        point: point.position,
        width: 64,
        height: 74,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showSafePointInfoSheet(context, point),
          child: MapMarkerBuilder.safePointMarker(),
        ),
      ));
    }
    return markers;
  }

  List<fm.Polygon> _buildPolygons() {
    return _mapCtrl.dangerZones
        .map(
          (zone) => fm.Polygon(
            points: zone.boundary,
            color: AppColors.mapDanger,
            borderColor: AppColors.primary,
            borderStrokeWidth: 2,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const NidaaAppBar(transparent: true),
      body: Stack(
        children: [
          Obx(() {
            final userLocation = _mapCtrl.userLocation.value;
            if (userLocation == null) {
              return const _LocationMissingCard();
            }
            return fm.FlutterMap(
              mapController: _map,
              options: fm.MapOptions(
                initialCenter: userLocation,
                initialZoom: 15,
                interactionOptions: const fm.InteractionOptions(
                  flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
                ),
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: MapOfflineService.tileUrl,
                  subdomains: MapOfflineService.subdomains,
                  userAgentPackageName: 'com.nidaa.app',
                  // يقرأ من كاش FMTC أولاً ثم الشبكة (متطلب 4.9).
                  tileProvider: MapOfflineService.tileProvider(),
                ),
                fm.PolygonLayer(polygons: _buildPolygons()),
                fm.MarkerLayer(markers: _buildMarkers()),
                if (_mapCtrl.isTracking.value)
                  fm.MarkerLayer(
                    markers: [
                      fm.Marker(
                        point: userLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.infoBlue,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }),
          Positioned(
            bottom: 28,
            left: 16,
            child: _MyLocationButton(onPressed: _recenterToUser),
          ),
          Obx(
            () => _mapCtrl.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LocationMissingCard extends StatelessWidget {
  const _LocationMissingCard();

  @override
  Widget build(BuildContext context) {
    final mapCtrl = Get.find<MapController>();
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 40, color: AppColors.textMedium),
            const SizedBox(height: 12),
            Text(
              AppStrings.mapLocationMissing,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.mapLocationHint,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: mapCtrl.startTracking,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MyLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.my_location, color: AppColors.infoBlue),
        tooltip: AppStrings.myLocation,
        onPressed: onPressed,
      ),
    );
  }
}