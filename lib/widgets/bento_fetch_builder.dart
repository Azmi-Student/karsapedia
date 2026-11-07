import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/cache_service.dart';

/// Komponen All-in-One Universal untuk Auto-Fetch dan SWR Cache di seluruh halaman Karsapedia
class BentoFetchBuilder<T> extends StatefulWidget {
  /// Kunci unik untuk cache SWR (misal: 'user_profile', 'tryout_list').
  /// Jika diisi, data akan tampil instan (0 detik) dari cache lalu otomatis diperbarui di latar belakang.
  final String? cacheKey;

  /// Fungsi asinkron untuk mengambil data dari backend API
  final Future<T> Function() fetcher;

  /// Builder utama saat data berhasil tersedia
  /// `isRefreshing`: true jika data lama sedang ditampilkan sambil menunggu background fetch selesai
  final Widget Function(BuildContext context, T data, bool isRefreshing) builder;

  /// Builder opsional untuk tampilan loading (default: Bento Shimmer Skeleton)
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder opsional untuk tampilan error
  final Widget Function(BuildContext context, dynamic error, Future<void> Function() retry)? errorBuilder;

  /// Builder opsional jika data kosong
  final Widget Function(BuildContext context, Future<void> Function() retry)? emptyBuilder;

  /// Fungsi pemeriksa apakah data dianggap kosong (misal: `(list) => list.isEmpty`)
  final bool Function(T data)? isEmpty;

  /// Aktifkan fitur tarik ke bawah untuk refresh (default: true)
  final bool enablePullToRefresh;

  /// Abaikan cache dan paksa fetch dari server dari awal (default: false)
  final bool forceRefresh;

  /// Masa berlaku cache sebelum dianggap basi (default: 5 menit)
  final Duration cacheTTL;

  /// Interval auto-refresh berkala (opsional, misal tiap 5-10 detik)
  final Duration? autoRefreshInterval;

  /// Trigger eksternal untuk re-fetch otomatis (misal saat tab aktif atau counter berpindah)
  final dynamic refreshTrigger;

  /// Fungsi deserializer jika data disimpan ke disk persistent
  final T Function(dynamic json)? fromJson;

  /// Fungsi serializer jika data disimpan ke disk persistent
  final dynamic Function(T item)? toJson;

  const BentoFetchBuilder({
    super.key,
    this.cacheKey,
    required this.fetcher,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.isEmpty,
    this.enablePullToRefresh = true,
    this.forceRefresh = false,
    this.cacheTTL = const Duration(minutes: 5),
    this.autoRefreshInterval,
    this.refreshTrigger,
    this.fromJson,
    this.toJson,
  });

  @override
  State<BentoFetchBuilder<T>> createState() => BentoFetchBuilderState<T>();
}

class BentoFetchBuilderState<T> extends State<BentoFetchBuilder<T>> with WidgetsBindingObserver {
  T? _data;
  bool _isLoading = true;
  bool _isRefreshing = false;
  dynamic _error;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _setupPeriodicRefresh();
  }

  @override
  void didUpdateWidget(covariant BentoFetchBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey || oldWidget.forceRefresh != widget.forceRefresh) {
      _initializeData();
    } else if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      if (_data != null) {
        _fetchFreshData(isBackground: true);
      } else {
        _initializeData();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_isLoading && !_isRefreshing) {
      _fetchFreshData(isBackground: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    super.dispose();
  }

  /// Metode publik untuk memicu re-fetch dari luar
  Future<void> refresh() async {
    await _fetchFreshData(isBackground: _data != null);
  }

  void _setupPeriodicRefresh() {
    if (widget.autoRefreshInterval != null) {
      _periodicTimer = Timer.periodic(widget.autoRefreshInterval!, (_) {
        if (mounted && !_isLoading && !_isRefreshing) {
          _fetchFreshData(isBackground: true);
        }
      });
    }
  }

  Future<void> _initializeData() async {
    // 1. Jika ada cacheKey dan tidak dipaksa refresh: Cek cache terlebih dahulu
    if (widget.cacheKey != null && !widget.forceRefresh) {
      final cached = await CacheService.get<T>(
        widget.cacheKey!,
        ttl: widget.cacheTTL,
        fromJson: widget.fromJson,
      );

      if (cached != null && mounted) {
        setState(() {
          _data = cached;
          _isLoading = false;
          _isRefreshing = true; // Tandai sedang mengambil data baru di background
          _error = null;
        });

        // Lakukan background fetch secara hening
        _fetchFreshData(isBackground: true);
        return;
      }
    }

    // 2. Jika tidak ada cache: Tampilkan loading state dan fetch langsung
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isRefreshing = false;
        _error = null;
      });
    }

    await _fetchFreshData(isBackground: false);
  }

  Future<void> _fetchFreshData({required bool isBackground}) async {
    try {
      final freshData = await widget.fetcher();

      // Simpan ke cache jika cacheKey disediakan
      if (widget.cacheKey != null) {
        await CacheService.set<T>(
          widget.cacheKey!,
          freshData,
          toJson: widget.toJson,
        );
      }

      if (!mounted) return;

      setState(() {
        _data = freshData;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      // Jika sudah ada data dari cache sebelumnya, jangan rusak layar dengan error merah.
      // Cukup hentikan status refreshing dan biarkan data cache tetap tampil.
      if (_data != null) {
        setState(() {
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _handleManualRefresh() async {
    await _fetchFreshData(isBackground: _data != null);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kondisi Loading Pertama Kali (Tanpa Cache)
    if (_isLoading && _data == null) {
      return widget.loadingBuilder != null
          ? widget.loadingBuilder!(context)
          : const BentoDefaultSkeletonLoader();
    }

    // 2. Kondisi Error Pertama Kali (Tanpa Cache)
    if (_error != null && _data == null) {
      final errorWidget = widget.errorBuilder != null
          ? widget.errorBuilder!(context, _error, _handleManualRefresh)
          : BentoDefaultErrorView(
              error: _error,
              onRetry: _handleManualRefresh,
            );

      return widget.enablePullToRefresh
          ? _wrapWithRefreshIndicator(
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: errorWidget,
              ),
            )
          : errorWidget;
    }

    // 3. Kondisi Data Kosong
    if (_data != null && widget.isEmpty != null && widget.isEmpty!(_data as T)) {
      final emptyWidget = widget.emptyBuilder != null
          ? widget.emptyBuilder!(context, _handleManualRefresh)
          : BentoDefaultEmptyView(onRefresh: _handleManualRefresh);

      return widget.enablePullToRefresh
          ? _wrapWithRefreshIndicator(
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: emptyWidget,
              ),
            )
          : emptyWidget;
    }

    // 4. Kondisi Sukses (Menampilkan Data + Opsional Pull-to-Refresh)
    final content = widget.builder(context, _data as T, _isRefreshing);

    if (widget.enablePullToRefresh) {
      return _wrapWithRefreshIndicator(content);
    }

    return content;
  }

  Widget _wrapWithRefreshIndicator(Widget child) {
    return RefreshIndicator(
      onRefresh: _handleManualRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      strokeWidth: 2.2,
      child: child,
    );
  }
}

// ==========================================
// DEFAULT BENTO SKELETON LOADER
// ==========================================
class BentoDefaultSkeletonLoader extends StatefulWidget {
  const BentoDefaultSkeletonLoader({super.key});

  @override
  State<BentoDefaultSkeletonLoader> createState() => _BentoDefaultSkeletonLoaderState();
}

class _BentoDefaultSkeletonLoaderState extends State<BentoDefaultSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final opacity = 0.4 + (_animCtrl.value * 0.4);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Skeleton
              Container(
                width: 140,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 220,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity * 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 24),

              // Card Hero Skeleton
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 16),

              // Menu Card Skeletons
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity * 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity * 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// DEFAULT BENTO ERROR VIEW
// ==========================================
class BentoDefaultErrorView extends StatelessWidget {
  final dynamic error;
  final Future<void> Function() onRetry;

  const BentoDefaultErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 26,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Menghubungkan Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Terjadi kendala saat mengambil data terbaru dari server backend.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// DEFAULT BENTO EMPTY VIEW
// ==========================================
class BentoDefaultEmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const BentoDefaultEmptyView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 26,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Data Tersedia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Konten atau materi belum tersedia pada kategori ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Perbarui Halaman'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

