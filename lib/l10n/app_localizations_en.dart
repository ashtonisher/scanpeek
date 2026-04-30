// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get scanGuide => 'Align QR code within the frame';

  @override
  String get adNotice => 'An ad will play before opening the link.';

  @override
  String get urlSheetTitle => 'URL Scan Result';

  @override
  String get textSheetTitle => 'Scan Result';

  @override
  String get safe => '✅ No Threats Detected';

  @override
  String get danger => '⚠️ Threat Detected';

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
  String get safeBrowsingResultSafe => 'No threats detected.';

  @override
  String safeBrowsingResultDanger(String threat) {
    return '$threat detected.\nVisiting this site is not recommended.';
  }

  @override
  String get checking => 'Checking...';

  @override
  String get safeOpenButton => 'Check Link';

  @override
  String get openAnywayButton => 'Open Anyway';

  @override
  String get ignoreAndOpen => 'Ignore Warning & Open';

  @override
  String get openLinkButton => 'Open Link';

  @override
  String get closeButton => 'Close';

  @override
  String get galleryNoQrFound => 'No QR code found in this image.';

  @override
  String get galleryAnalyzing => 'Analyzing QR code...';
}
