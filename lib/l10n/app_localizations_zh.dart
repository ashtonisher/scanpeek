// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get scanGuide => '扫描二维码或选择二维码图片。';

  @override
  String get adNotice => '观看广告后即可打开链接。';

  @override
  String get urlSheetTitle => 'URL 扫描结果';

  @override
  String get textSheetTitle => '扫描结果';

  @override
  String get safe => '✅ 未检测到威胁';

  @override
  String get danger => '⚠️ 检测到威胁';

  @override
  String get threatMalware => '恶意软件';

  @override
  String get threatPhishing => '钓鱼/诈骗';

  @override
  String get threatUnwanted => '有害软件';

  @override
  String get threatHarmfulApp => '有害应用';

  @override
  String get threatUnknown => '威胁';

  @override
  String get safeBrowsingResultSafe => '未检测到威胁。';

  @override
  String safeBrowsingResultDanger(String threat) {
    return '检测到$threat。\n不建议访问此网站。';
  }

  @override
  String get checking => '检查中...';

  @override
  String get safeOpenButton => '检查链接';

  @override
  String get openAnywayButton => '直接打开';

  @override
  String get ignoreAndOpen => '忽略警告并打开';

  @override
  String get openLinkButton => '打开链接';

  @override
  String get closeButton => '关闭';

  @override
  String get galleryNoQrFound => '在此图片中找不到二维码。';

  @override
  String get galleryAnalyzing => '正在解析二维码...';

  @override
  String get copyLinkTooltip => '复制链接';

  @override
  String get linkCopiedMessage => '已复制链接。';

  @override
  String get galleryButton => '相册';
}
