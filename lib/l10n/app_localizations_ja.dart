// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get scanGuide => 'QRコードを枠内に合わせてください';

  @override
  String get adNotice => '広告を視聴後にリンクを開けます。';

  @override
  String get urlSheetTitle => 'URLスキャン結果';

  @override
  String get textSheetTitle => 'スキャン結果';

  @override
  String get safe => '✅ 脅威未検出';

  @override
  String get danger => '⚠️ 脅威検出';

  @override
  String get threatMalware => 'マルウェア';

  @override
  String get threatPhishing => 'フィッシング／詐欺';

  @override
  String get threatUnwanted => '望ましくないソフトウェア';

  @override
  String get threatHarmfulApp => '有害アプリ';

  @override
  String get threatUnknown => '脅威';

  @override
  String get safeBrowsingResultSafe => '脅威は検出されませんでした。';

  @override
  String safeBrowsingResultDanger(String threat) {
    return '$threatが検出されました。\nこのサイトへの訪問はお勧めしません。';
  }

  @override
  String get checking => '確認中...';

  @override
  String get safeOpenButton => '🔍 リンクを検査する';

  @override
  String get openAnywayButton => 'そのまま開く';

  @override
  String get ignoreAndOpen => '警告を無視して開く';

  @override
  String get closeButton => '閉じる';
}
