// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get scanGuide => 'Align QR code or barcode within the frame';

  @override
  String get adNotice => 'An ad will play before opening the link.';

  @override
  String get urlSheetTitle => 'URL Scan Result';

  @override
  String get textSheetTitle => 'Scan Result';

  @override
  String get safe => '✅ Safe';

  @override
  String get danger => '⚠️ Danger';

  @override
  String get threatMalware => 'Malware';

  @override
  String get threatPhishing => 'Phishing / Scam';

  @override
  String get threatUnwanted => 'Unwanted Software';

  @override
  String get threatHarmfulApp => 'Harmful App';

  @override
  String get threatUnknown => 'Threat';

  @override
  String get safeBrowsingResultSafe =>
      'Google Safe Browsing result\nNo threats detected.\nRedirecting shortly...';

  @override
  String safeBrowsingResultDanger(String threat) {
    return 'Google Safe Browsing result\n$threat detected.\nVisiting this site is not recommended.';
  }

  @override
  String get checking => 'Checking...';

  @override
  String get safeOpenButton => '🔒 Check & Open Safely';

  @override
  String get openAnywayButton => 'Open Anyway';

  @override
  String get ignoreAndOpen => 'Ignore Warning & Open';

  @override
  String get closeButton => 'Close';
}
