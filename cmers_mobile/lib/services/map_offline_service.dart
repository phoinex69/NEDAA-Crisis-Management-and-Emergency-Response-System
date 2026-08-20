import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

/// تحميل الخرائط الأساسية مسبقاً للعمل أوفلاين (متطلب 4.9):
/// تحميل بلاطات CartoDB حول موقع المستخدم عبر FMTC (زوم 11→16، سقف 300MB).
class MapOfflineService extends GetxService {
  static MapOfflineService get instance => Get.find<MapOfflineService>();

  static const String storeName = 'nidaa_offline';

  /// بلاطات OpenStreetMap القياسية الملوّنة — بلا مفتاح، ومطابقة للنمط
  /// الافتراضي في لوحة التحكم (متطلب 4.6).
  static const String tileUrl =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> subdomains = ['a', 'b', 'c'];

  /// سقف الحجم بالكيلوبايت (300MB).
  static const double _maxDownloadKiB = 300.0 * 1024;

  final RxBool isDownloading = false.obs;
  final RxDouble progress = 0.0.obs; // 0..100
  final RxString statusText = ''.obs;
  final Rx<double?> cachedSizeKiB = Rx<double?>(null);

  StreamSubscription<DownloadProgress>? _progressSub;

  /// تهيئة خلفية FMTC مرة واحدة عند إقلاع التطبيق.
  ///
  /// ينشئ أيضاً متجر البلاطات [storeName] فوراً — [tileProvider] يشير إليه
  /// بالاسم فقط دون التحقق من وجوده، والمتجر غير الموجود يجعل كل طلبات
  /// البلاطات تفشل بصمت (خريطة فارغة) حتى لو كان الموقع الجغرافي يعمل.
  /// سابقاً كان المتجر يُنشأ فقط عند تحميل منطقة أوفلاين يدوياً، فلا يوجد
  /// عند أول فتح للخريطة على تثبيت جديد.
  static Future<void> initFmtc() async {
    try {
      await FMTCObjectBoxBackend().initialise();
      const store = FMTCStore(storeName);
      if (!await store.manage.ready) {
        await store.manage.create();
        await store.metadata.set(key: 'urlTemplate', value: tileUrl);
      }
    } catch (_) {
      // الباك اند غير متاح (مثلاً على الويب) — تُترك بلا كاش.
    }
  }

  Future<FMTCStore> _store() async {
      const store = FMTCStore(storeName);
    if (!await store.manage.ready) {
      await store.manage.create();
      await store.metadata.set(key: 'urlTemplate', value: tileUrl);
    }
    return store;
  }

  /// TileProvider يقرأ من الكاش أولاً ثم يرفع من الشبكة —
  /// أوفلاين = البلاطات المحمّلة تظهر بدون إنترنت.
  static TileProvider tileProvider() {
    return FMTCTileProvider(
      stores: const {storeName: BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );
  }

  /// تحميل منطقة دائرية نصف قطرها [radiusKm] حول [center].
  Future<void> downloadRegion({
    required LatLng center,
    double radiusKm = 10,
    int minZoom = 11,
    int maxZoom = 16,
  }) async {
    if (isDownloading.value) return;
    isDownloading.value = true;
    progress.value = 0;
    statusText.value = 'جارٍ التحضير...';
    try {
      final store = await _store();
      final region = CircleRegion(center, radiusKm).toDownloadable(
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: TileLayer(
          urlTemplate: tileUrl,
          subdomains: subdomains,
          userAgentPackageName: 'com.nidaa.app',
        ),
      );
      final streams = store.download.startForeground(region: region);
      _progressSub?.cancel();
      _progressSub = streams.downloadProgress.listen((p) {
        progress.value = p.percentageProgress.clamp(0.0, 100.0).toDouble();
        final sizeKiB = p.successfulTilesSize +
            p.existingTilesSize +
            p.seaTilesSize;
        cachedSizeKiB.value = sizeKiB;
        statusText.value =
            '${p.attemptedTilesCount}/${p.maxTilesCount} بلاطة — '
            '${(sizeKiB / 1024).toStringAsFixed(1)}MB';
        if (sizeKiB > _maxDownloadKiB) {
          statusText.value = 'بلغ التحميل سقف 300MB — يتوقف الآن';
          unawaited(store.download.cancel());
        }
      });
      await streams.downloadProgress.drain<void>();
      statusText.value = 'اكتمل تحميل خريطة منطقتك';
    } catch (e) {
      statusText.value = 'تعذر التحميل: $e';
    } finally {
      isDownloading.value = false;
      _progressSub?.cancel();
      _progressSub = null;
    }
  }

  /// إيقاف التحميل الجاري.
  Future<void> cancelDownload() async {
    if (!isDownloading.value) return;
    try {
      await const FMTCStore(storeName).download.cancel();
    } catch (_) {}
  }

  /// حجم الخريطة المخزنة محلياً (KiB) — null إذا لم توجد.
  Future<void> refreshCacheSize() async {
    try {
      const store = FMTCStore(storeName);
      if (!await store.manage.ready) {
        cachedSizeKiB.value = null;
        return;
      }
      final stats = await store.stats.all;
      cachedSizeKiB.value = stats.size;
    } catch (_) {
      cachedSizeKiB.value = null;
    }
  }

  @override
  void onClose() {
    _progressSub?.cancel();
    super.onClose();
  }
}