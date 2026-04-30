# ScanPeek

QR코드 & 바코드 스캐너 앱. Google Safe Browsing API로 URL 안전 검사를 지원합니다.

## 기능

- QR코드 / 바코드 즉시 스캔
- 갤러리 이미지에서 QR코드 스캔
- URL 스캔 시 도메인 미리보기 (탭으로 바로 열기)
- 커스텀 스키마(앱 딥링크) 실행 지원
- Google Safe Browsing API 연동 안전 검사
- 위험 링크 경고 및 사용자 선택 이동
- 크레딧 기반 안전 검사 (첫 설치 시 1개 무료, 광고 시청마다 충전)
- AdMob 배너 / 전면 / 보상형 광고
- 다국어 지원: 한국어, English, 日本語, 中文

## 시작하기

### 필수 설정

`lib/config.dart`를 `lib/config.example.dart`를 참고해 작성하세요.

```dart
const String safeBrowsingApiKey = 'YOUR_API_KEY';
const String bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
const String interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
const String rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
```

### 빌드

```bash
flutter pub get
flutter gen-l10n
flutter build appbundle --release
```

## 기술 스택

- Flutter / Dart
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) — 카메라 스캔 및 이미지 분석
- [image_picker](https://pub.dev/packages/image_picker) — 갤러리 이미지 선택
- [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) — AdMob 광고
- [http](https://pub.dev/packages/http) — Safe Browsing API 통신
- [shared_preferences](https://pub.dev/packages/shared_preferences) — 크레딧 로컬 저장
- [url_launcher](https://pub.dev/packages/url_launcher) — 인앱 브라우저 / 외부 앱 실행

## 주의사항

- `lib/config.dart`, `android/key.properties`, `*.jks` 파일은 git에서 제외됩니다.
- 릴리즈 키스토어(`scanpeek.jks`)는 분실 시 앱 업데이트가 불가능하므로 안전한 곳에 백업하세요.
