// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get scanGuide => 'QRコードをスキャンするか、QR画像を選択してください。';

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
  String get checkUnavailable => '本日のリンク検査の回数を使い切りました。';

  @override
  String get checkError => 'リンク検査に失敗しました。しばらくして再度お試しください。';

  @override
  String get checking => '確認中...';

  @override
  String get safeOpenButton => 'リンクを検査する';

  @override
  String get openAnywayButton => 'そのまま開く';

  @override
  String get ignoreAndOpen => '警告を無視して開く';

  @override
  String get openLinkButton => 'リンクを開く';

  @override
  String get closeButton => '閉じる';

  @override
  String get galleryNoQrFound => '画像からQRコードが見つかりませんでした。';

  @override
  String get galleryAnalyzing => 'QRコードを解析中...';

  @override
  String get copyLinkTooltip => 'リンクをコピー';

  @override
  String get linkCopiedMessage => 'リンクをコピーしました。';

  @override
  String get galleryButton => 'ギャラリー';
}
