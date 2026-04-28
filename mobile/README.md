# TirzPlotter Mobile

Small Flutter WebView shell for the hosted TirzPlotter web app:

```text
https://tirzplotter.netlify.app
```

The Netlify app owns the UI and local browser storage. This mobile project only packages the site as an Android app.

## Run

Install Flutter, then from this folder:

```sh
flutter pub get
flutter run
```

## Data

The app uses the same browser storage behavior as the hosted site. Export/import remains the backup path for moving data between browsers or devices.
