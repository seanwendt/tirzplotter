# Google Play Release Checklist

## Account

- Create a Google Play Console developer account.
- Pay the one-time Google Play registration fee.
- Complete identity and contact verification.
- If using a new personal account, plan for the closed-testing requirement before production release.

## App Identity

- Package ID: `app.tirzplotter.mobile`
- App name: `TirzPlotter`
- Privacy policy URL: `https://tirzplotter.netlify.app/privacy.html`

## Signing

Create an upload keystore:

```sh
cd mobile/android
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Create `mobile/android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Do not commit `key.properties` or `*.jks`.

## Build

```sh
cd mobile
flutter analyze
flutter build appbundle --release
```

Upload:

```text
mobile/build/app/outputs/bundle/release/app-release.aab
```

## Store Listing

- Short description
- Full description
- App icon
- Feature graphic
- Phone screenshots
- App category
- Content rating questionnaire
- Data Safety form
- Medical/health disclaimer in listing copy

## Notes

The app is a WebView wrapper around `https://tirzplotter.netlify.app`. Export and import are bridged natively on Android so JSON backups work from inside the app.
