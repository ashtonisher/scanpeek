// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get scanGuide => 'QR코드를 스캔하거나 QR 이미지를 선택하세요.';

  @override
  String get adNotice => '광고 시청 후 이동할 수 있습니다.';

  @override
  String get urlSheetTitle => 'URL 스캔 결과';

  @override
  String get textSheetTitle => '스캔 결과';

  @override
  String get safe => '✅ 위협 미탐지';

  @override
  String get danger => '⚠️ 위험 감지';

  @override
  String get threatMalware => '악성코드';

  @override
  String get threatPhishing => '피싱/사기';

  @override
  String get threatUnwanted => '유해 소프트웨어';

  @override
  String get threatHarmfulApp => '유해 앱';

  @override
  String get threatUnknown => '위협';

  @override
  String get safeBrowsingResultSafe => '위협이 탐지되지 않았습니다. 이동 중...';

  @override
  String safeBrowsingResultDanger(String threat) {
    return '$threat이 감지되었습니다.\n방문을 권장하지 않습니다.';
  }

  @override
  String get checking => '검사 중...';

  @override
  String get safeOpenButton => '링크 검사하기';

  @override
  String get openAnywayButton => '그냥 열기';

  @override
  String get ignoreAndOpen => '경고 무시하고 열기';

  @override
  String get openLinkButton => '링크 열기';

  @override
  String get closeButton => '닫기';

  @override
  String get galleryNoQrFound => '이미지에서 QR코드를 찾을 수 없어요.';

  @override
  String get galleryAnalyzing => 'QR코드 분석 중...';

  @override
  String get galleryButton => '갤러리';
}
