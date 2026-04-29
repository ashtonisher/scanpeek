import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

void main() {
  // Flutter 엔진 초기화 (카메라 같은 네이티브 기능 사용 전 필수)
  WidgetsFlutterBinding.ensureInitialized();
  // AdMob SDK 초기화
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanPeek',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ScannerPage(),
    );
  }
}

// 스캔 메인 화면 — 카메라 뷰 + 결과 처리
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  // MobileScannerController: 카메라 시작/정지/플래시/전후면 전환 담당
  final MobileScannerController _controller = MobileScannerController();

  // 중복 감지 방지 플래그 — 바텀시트가 떠 있는 동안 추가 스캔 막기
  bool _isScanning = true;

  // 하단 배너 광고 — 스캔 화면에 항상 표시
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // 상단 배너 광고 — 바텀시트가 열릴 때만 표시 (하단 배너가 가려지는 보완)
  BannerAd? _topBannerAd;
  bool _isTopBannerAdReady = false;
  bool _isSheetOpen = false;

  // 전면 광고 — 10회 스캔마다 1번 표시
  InterstitialAd? _interstitialAd;
  int _scanCount = 0;
  bool _isShowingAdForOpen = false;

  // 갤러리 이미지 분석 상태
  bool _isAnalyzing = false;
  bool _isAnalyzingFailed = false;
  String? _analyzingImagePath;

  // 안전 검사 크레딧 — SharedPreferences로 영구 저장
  // 첫 설치 시 1개 무료, 이후 광고 시청마다 2개 지급, 사용마다 1개 차감
  static const String _creditKey = 'safe_browse_credits';
  int _safeCredits = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
    _loadTopBannerAd();
    _loadInterstitialAd();
    _loadCredits();
  }

  // 앱 생명주기 감지 — 브라우저에서 돌아올 때 카메라 재시작
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 바텀시트가 닫힌 상태일 때만 카메라 재시작
      if (!_isSheetOpen) {
        _resumeScanning();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = !prefs.containsKey(_creditKey);
    if (isFirstLaunch) {
      // 첫 설치 시 무료 크레딧 1개 지급
      await prefs.setInt(_creditKey, 1);
    }
    if (!mounted) return;
    setState(() => _safeCredits = prefs.getInt(_creditKey) ?? 0);
  }

  Future<void> _saveCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditKey, credits);
    if (!mounted) return;
    setState(() => _safeCredits = credits);
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadTopBannerAd() {
    _topBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          // 전면 광고가 닫히면 다음 노출을 위해 다시 로드
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  // 10회 스캔마다 전면 광고 조건 충족 여부 확인
  bool _shouldShowInterstitialAd() {
    _scanCount++;
    return _scanCount % 2 == 0 && _interstitialAd != null;
  }

  // 전면 광고 표시 후 콜백 실행 — 광고 없으면 콜백 바로 실행
  // blockBackButton: true면 광고 중 뒤로가기 막기 (이동하기용)
  void _showInterstitialAdThen(
    VoidCallback onDone, {
    bool blockBackButton = false,
  }) {
    if (_interstitialAd == null) {
      onDone();
      return;
    }
    if (blockBackButton) setState(() => _isShowingAdForOpen = true);
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (blockBackButton) setState(() => _isShowingAdForOpen = false);
        // onDone 먼저 실행 후 다음 광고 로드 (카메라 재개와 충돌 방지)
        onDone();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (blockBackButton) setState(() => _isShowingAdForOpen = false);
        onDone();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // 갤러리에서 이미지 선택 후 QR/바코드 분석
  Future<void> _pickImageFromGallery() async {
    // 이전 오버레이 상태 초기화 후 갤러리 열기
    _dismissGalleryOverlay();

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _isAnalyzing = true;
      _isAnalyzingFailed = false;
      _analyzingImagePath = file.path;
    });

    final capture = await _controller.analyzeImage(file.path);
    if (!mounted) return;

    final barcode = capture?.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) {
      setState(() {
        _isAnalyzing = false;
        _isAnalyzingFailed = true;
      });
      return;
    }

    _dismissGalleryOverlay();
    setState(() => _isScanning = false);
    _controller.stop();

    final value = barcode.rawValue!;
    final valueLower = value.toLowerCase();
    final isHttpUrl =
        valueLower.startsWith('http://') || valueLower.startsWith('https://');
    final isCustomScheme = !isHttpUrl && valueLower.contains('://');
    if (isHttpUrl) {
      final uri = Uri.parse(value);
      final normalizedUrl = uri
          .replace(
            scheme: uri.scheme.toLowerCase(),
            host: uri.host.toLowerCase(),
          )
          .toString();
      _showUrlPreview(normalizedUrl, showSafePreview: true);
    } else if (isCustomScheme) {
      _showUrlPreview(value, showSafePreview: false);
    } else {
      _showTextResult(value);
    }
  }

  void _dismissGalleryOverlay() {
    setState(() {
      _isAnalyzing = false;
      _isAnalyzingFailed = false;
      _analyzingImagePath = null;
    });
  }

  // 바코드가 감지될 때마다 호출되는 콜백
  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return; // 이미 처리 중이면 무시

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isScanning = false);
    _controller.stop();

    final value = barcode.rawValue!;
    final valueLower = value.toLowerCase();
    final isHttpUrl =
        valueLower.startsWith('http://') || valueLower.startsWith('https://');
    final isCustomScheme = !isHttpUrl && valueLower.contains('://');
    if (isHttpUrl) {
      final uri = Uri.parse(value);
      final normalizedUrl = uri
          .replace(
            scheme: uri.scheme.toLowerCase(),
            host: uri.host.toLowerCase(),
          )
          .toString();
      _showUrlPreview(normalizedUrl, showSafePreview: true);
    } else if (isCustomScheme) {
      _showUrlPreview(value, showSafePreview: false);
    } else {
      _showTextResult(value);
    }
  }

  // URL 스캔 결과 — 도메인/경로 미리보기 바텀시트 표시
  void _showUrlPreview(String url, {required bool showSafePreview}) {
    final uri = Uri.parse(url);
    setState(() => _isSheetOpen = true);
    final shouldShowAd = _shouldShowInterstitialAd();
    bool handledByButton = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UrlPreviewSheet(
        url: url,
        domain: uri.host.isNotEmpty ? uri.host : uri.scheme,
        onOpen: () {
          handledByButton = true;
          Navigator.pop(context);
          _launchUrl(url);
        },
        onClose: () {
          handledByButton = true;
          Navigator.pop(context);
          if (shouldShowAd) {
            _showAdNoticeSnackBar();
            _showInterstitialAdThen(_resumeScanning);
          } else {
            _resumeScanning();
          }
        },
        onSafePreview: showSafePreview
            ? (onAdDone) => _handleSafePreview(url, onAdDone)
            : null,
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _isSheetOpen = false);
      // 버튼으로 처리된 경우 중복 호출 방지 (뒤로가기로 닫은 경우에만 재개)
      if (!handledByButton) _resumeScanning();
    });
  }

  // 크레딧 있으면 즉시 검사, 없으면 보상형 광고 후 크레딧 2개 지급 후 검사
  void _handleSafePreview(String url, VoidCallback onAdDone) {
    if (_safeCredits > 0) {
      // 크레딧 차감 후 즉시 검사
      _saveCredits(_safeCredits - 1);
      onAdDone();
    } else {
      // 크레딧 없음 → 광고 시청 후 크레딧 2개 지급 → 1개 차감 후 검사
      _showRewardedAdForSheet(() {
        _saveCredits(2 - 1); // 2개 지급 후 1개 즉시 사용
        onAdDone();
      });
    }
  }

  // 보상형 광고 표시 → 완료 후 onAdDone 콜백 실행
  void _showRewardedAdForSheet(VoidCallback onAdDone) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDone();
            },
          );
          // onUserEarnedReward는 리워드 지급 시점, onAdDismissedFullScreenContent는 닫힘 시점
          // 로직은 반드시 onAdDismissedFullScreenContent에서만 처리 — 이중 호출 방지
          ad.show(onUserEarnedReward: (adItem, reward) {});
        },
        onAdFailedToLoad: (error) {
          debugPrint('보상형 광고 로드 실패: ${error.message}');
          onAdDone();
        },
      ),
    );
  }

  // 텍스트/바코드 스캔 결과 바텀시트 표시
  void _showTextResult(String text) {
    setState(() => _isSheetOpen = true);
    final shouldShowAd = _shouldShowInterstitialAd();
    bool handledByButton = false;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TextResultSheet(
        text: text,
        onClose: () {
          handledByButton = true;
          Navigator.pop(context);
          if (shouldShowAd) {
            _showAdNoticeSnackBar();
            _showInterstitialAdThen(_resumeScanning);
          } else {
            _resumeScanning();
          }
        },
      ),
    ).then((_) {
      setState(() => _isSheetOpen = false);
      if (!handledByButton) _resumeScanning();
    });
  }

  // 전면 광고 표시 전 안내 스낵바
  void _showAdNoticeSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.adNotice),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 외부 브라우저 앱으로 URL 열기
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  // 바텀시트 닫힌 후 카메라 재개
  void _resumeScanning() {
    if (!mounted) return;
    // 전면 광고 후 카메라가 검게 보이는 현상 방지를 위해 짧은 딜레이
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isScanning = true);
      _controller.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _bannerAd?.dispose();
    _topBannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이동하기 광고 중 뒤로가기 차단 / 갤러리 오버레이 중 뒤로가기로 닫기
    return PopScope(
      canPop: !_isShowingAdForOpen && !_isAnalyzing && !_isAnalyzingFailed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && (_isAnalyzing || _isAnalyzingFailed)) {
          _dismissGalleryOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            children: [
              Image.asset('assets/icon/app_icon.png', width: 28, height: 28),
              const SizedBox(width: 8),
              const Text('ScanPeek', style: TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            // 갤러리에서 이미지 선택
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              onPressed: _pickImageFromGallery,
            ),
            // 플래시 토글
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
            // 전면/후면 카메라 전환
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 상단 배너 — 바텀시트가 열릴 때 영역 확보 (광고 로드 전에도 높이 유지)
              if (_isSheetOpen)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: (_isTopBannerAdReady && _topBannerAd != null)
                      ? AdWidget(ad: _topBannerAd!)
                      : const SizedBox.shrink(),
                ),
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    // 카메라 프리뷰 + 스캔 엔진
                    MobileScanner(controller: _controller, onDetect: _onDetect),
                    // 반투명 스캔 가이드 박스 오버레이
                    _ScanOverlay(),
                    // 갤러리 이미지 분석 중 오버레이
                    if ((_isAnalyzing || _isAnalyzingFailed) &&
                        _analyzingImagePath != null)
                      _GalleryAnalyzingOverlay(
                        imagePath: _analyzingImagePath!,
                        isFailed: _isAnalyzingFailed,
                        onDismiss: _dismissGalleryOverlay,
                        onRetry: _pickImageFromGallery,
                      ),
                  ],
                ),
              ),
              // 하단 안내 문구 + 배너 광고 영역
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.scanGuide,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // 광고 영역 — 로드 전에도 높이 확보해서 카메라 영역 떨림 방지
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: (_isBannerAdReady && _bannerAd != null)
                          ? AdWidget(ad: _bannerAd!)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 스캔 가이드 사각형 오버레이
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigoAccent, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// 갤러리 이미지 분석 중 오버레이 — 선택한 이미지 미리보기 + 스캔 애니메이션
class _GalleryAnalyzingOverlay extends StatefulWidget {
  final String imagePath;
  final bool isFailed;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;
  const _GalleryAnalyzingOverlay({
    required this.imagePath,
    required this.onDismiss,
    required this.onRetry,
    this.isFailed = false,
  });

  @override
  State<_GalleryAnalyzingOverlay> createState() =>
      _GalleryAnalyzingOverlayState();
}

class _GalleryAnalyzingOverlayState extends State<_GalleryAnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanLine;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_GalleryAnalyzingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 실패 상태가 끝나면 페이드아웃
    if (oldWidget.isFailed && !widget.isFailed) {
      setState(() => _opacity = 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // 이미지가 카메라 뷰 전체를 채움
          Positioned.fill(
            child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
          ),
          if (!widget.isFailed)
            // 스캔 라인
            AnimatedBuilder(
              animation: _scanLine,
              builder: (_, _) => Positioned(
                top:
                    _scanLine.value *
                    (MediaQuery.of(context).size.height * 0.5),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.indigoAccent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.isFailed)
            // 실패 시 반투명 오버레이
            Container(
              color: Colors.black.withAlpha(160),
              child: Stack(
                children: [
                  // 아이콘 + 문구 — 정중앙
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.redAccent,
                            size: 80,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.galleryNoQrFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 버튼 — 하단 고정
                  Positioned(
                    bottom: 48,
                    left: 24,
                    right: 24,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onDismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('닫기', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('갤러리', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 분석 중 텍스트 (하단 고정)
          if (!widget.isFailed)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                AppLocalizations.of(context)!.galleryAnalyzing,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// URL 스캔 결과 바텀시트
// - 이동하기: 즉시 브라우저
// - 안전하게 이동하기(강조): 보상형 광고 → Safe Browsing 검사 → 인라인 결과 표시
class UrlPreviewSheet extends StatefulWidget {
  final String url;
  final String domain;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final void Function(VoidCallback onAdDone)? onSafePreview;

  const UrlPreviewSheet({
    super.key,
    required this.url,
    required this.domain,
    required this.onOpen,
    required this.onClose,
    this.onSafePreview,
  });

  @override
  State<UrlPreviewSheet> createState() => _UrlPreviewSheetState();
}

class _UrlPreviewSheetState extends State<UrlPreviewSheet> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Safe Browsing 검사 상태
  bool _isChecking = false; // 검사 중
  bool _hasResult = false; // 결과 있음
  bool _isSafe = true;
  String? _threatType;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // 보상형 광고 요청 → 완료 후 Safe Browsing 검사
  void _requestSafePreview() {
    // 광고 시청 중이든 크레딧 사용 중이든 즉시 버튼 비활성화
    setState(() => _isChecking = true);
    widget.onSafePreview!(() => _runSafeBrowsing());
  }

  // Google Safe Browsing API 검사
  Future<void> _runSafeBrowsing() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
      _hasResult = false;
    });

    bool isSafe = true;
    String? threatType;

    try {
      final response = await http.post(
        Uri.parse(
          'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$safeBrowsingApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client': {
            'clientId': 'com.gubog.scanpeek',
            'clientVersion': '1.0.0',
          },
          'threatInfo': {
            'threatTypes': [
              'MALWARE',
              'SOCIAL_ENGINEERING',
              'UNWANTED_SOFTWARE',
              'POTENTIALLY_HARMFUL_APPLICATION',
            ],
            'platformTypes': ['ANDROID'],
            'threatEntryTypes': ['URL'],
            'threatEntries': [
              {'url': widget.url},
            ],
          },
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['matches'] != null && (data['matches'] as List).isNotEmpty) {
          isSafe = false;
          threatType = data['matches'][0]['threatType'];
        }
      }
    } catch (_) {
      // 네트워크 오류 시 안전으로 처리
    }

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _hasResult = true;
      _isSafe = isSafe;
      _threatType = threatType;
    });

    if (isSafe) {
      if (!mounted) return;
      widget.onOpen();
    }
    // 위험하면 경고만 표시 — 사용자가 직접 닫기
  }

  String _threatLabel(String? type, AppLocalizations l10n) {
    switch (type) {
      case 'MALWARE':
        return l10n.threatMalware;
      case 'SOCIAL_ENGINEERING':
        return l10n.threatPhishing;
      case 'UNWANTED_SOFTWARE':
        return l10n.threatUnwanted;
      case 'POTENTIALLY_HARMFUL_APPLICATION':
        return l10n.threatHarmfulApp;
      default:
        return l10n.threatUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 배너 광고 — 모달 상단 배치 (로드 전에도 높이 확보)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: (_isBannerAdReady && _bannerAd != null)
                ? AdWidget(ad: _bannerAd!)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          // 시트 헤더
          Row(
            children: [
              const Icon(Icons.link, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                l10n.urlSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          // 파비콘 + 도메인
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://www.google.com/s2/favicons?domain=${widget.domain}&sz=64',
                  width: 36,
                  height: 36,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.public, size: 36, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.domain,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 안전/위험 배지
              if (_hasResult)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isSafe ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSafe ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _isSafe ? l10n.safe : l10n.danger,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSafe
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 검사 결과 인라인 표시
          if (_hasResult) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSafe ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSafe ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                _isSafe
                    ? l10n.safeBrowsingResultSafe
                    : l10n.safeBrowsingResultDanger(
                        _threatLabel(_threatType, l10n),
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: _isSafe ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
            // 위험 사이트일 때만 무시하고 이동하기 버튼 표시
            if (!_isSafe) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: widget.onOpen,
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                  label: Text(
                    l10n.ignoreAndOpen,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          // 안전하게 이동하기 — 강조 버튼 (결과 없을 때, 커스텀 스키마 아닐 때만 표시)
          if (!_hasResult && widget.onSafePreview != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isChecking ? null : _requestSafePreview,
                icon: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user),
                label: Text(_isChecking ? l10n.checking : l10n.safeOpenButton),
              ),
            ),
          const SizedBox(height: 8),
          // 이동하기 — 보조 버튼 (TextButton)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: widget.onOpen,
              icon: const Icon(Icons.open_in_browser),
              label: Text(l10n.openAnywayButton),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// 텍스트/바코드 스캔 결과 바텀시트 — 결과를 그대로 표시 (텍스트 선택 복사 가능)
class TextResultSheet extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const TextResultSheet({super.key, required this.text, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시트 헤더
          Row(
            children: [
              const Icon(Icons.qr_code, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                l10n.textSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          // 스캔된 텍스트 (길게 눌러 복사 가능)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(text, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              child: Text(l10n.closeButton),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
