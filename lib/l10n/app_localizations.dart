import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @scanGuide.
  ///
  /// In en, this message translates to:
  /// **'Align QR code within the frame'**
  String get scanGuide;

  /// No description provided for @adNotice.
  ///
  /// In en, this message translates to:
  /// **'An ad will play before opening the link.'**
  String get adNotice;

  /// No description provided for @urlSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'URL Scan Result'**
  String get urlSheetTitle;

  /// No description provided for @textSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get textSheetTitle;

  /// No description provided for @safe.
  ///
  /// In en, this message translates to:
  /// **'✅ No Threats Detected'**
  String get safe;

  /// No description provided for @danger.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Threat Detected'**
  String get danger;

  /// No description provided for @threatMalware.
  ///
  /// In en, this message translates to:
  /// **'Malware'**
  String get threatMalware;

  /// No description provided for @threatPhishing.
  ///
  /// In en, this message translates to:
  /// **'Phishing / Scam'**
  String get threatPhishing;

  /// No description provided for @threatUnwanted.
  ///
  /// In en, this message translates to:
  /// **'Unwanted Software'**
  String get threatUnwanted;

  /// No description provided for @threatHarmfulApp.
  ///
  /// In en, this message translates to:
  /// **'Harmful App'**
  String get threatHarmfulApp;

  /// No description provided for @threatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Threat'**
  String get threatUnknown;

  /// No description provided for @safeBrowsingResultSafe.
  ///
  /// In en, this message translates to:
  /// **'No threats detected.'**
  String get safeBrowsingResultSafe;

  /// No description provided for @safeBrowsingResultDanger.
  ///
  /// In en, this message translates to:
  /// **'{threat} detected.\nVisiting this site is not recommended.'**
  String safeBrowsingResultDanger(String threat);

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @safeOpenButton.
  ///
  /// In en, this message translates to:
  /// **'🔍 Check Link'**
  String get safeOpenButton;

  /// No description provided for @openAnywayButton.
  ///
  /// In en, this message translates to:
  /// **'Open Anyway'**
  String get openAnywayButton;

  /// No description provided for @ignoreAndOpen.
  ///
  /// In en, this message translates to:
  /// **'Ignore Warning & Open'**
  String get ignoreAndOpen;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @galleryNoQrFound.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in this image.'**
  String get galleryNoQrFound;

  /// No description provided for @galleryAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing QR code...'**
  String get galleryAnalyzing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
