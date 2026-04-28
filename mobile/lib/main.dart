import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _tirzPlotterUrl = 'https://tirzplotter.netlify.app';
const _storageKey = 'tirzepatide_pk_doses_v1';
const _downloadsChannel = MethodChannel('tirzplotter/downloads');
const _defaultExportFilename = 'tirzepatide-doses.json';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TirzPlotterApp());
}

class TirzPlotterApp extends StatelessWidget {
  const TirzPlotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TirzPlotter',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3b82f6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff0a0f1a),
        useMaterial3: true,
      ),
      home: const TirzPlotterWebView(),
    );
  }
}

class TirzPlotterWebView extends StatefulWidget {
  const TirzPlotterWebView({super.key});

  @override
  State<TirzPlotterWebView> createState() => _TirzPlotterWebViewState();
}

class _TirzPlotterWebViewState extends State<TirzPlotterWebView> {
  late final WebViewController _controller;
  var _progress = 0;
  var _pageLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xff0a0f1a))
      ..addJavaScriptChannel(
        'TirzPlotterDownloads',
        onMessageReceived: _saveExport,
      )
      ..addJavaScriptChannel(
        'TirzPlotterImports',
        onMessageReceived: (_) => _importJson(),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageStarted: (_) => setState(() {
            _error = null;
            _pageLoaded = false;
          }),
          onPageFinished: (_) {
            setState(() {
              _progress = 100;
              _pageLoaded = true;
            });
            _installWebAppBridge();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              setState(() => _error = error.description);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_tirzPlotterUrl));
  }

  Future<void> _installWebAppBridge() async {
    await _controller.runJavaScript('''
      (function () {
        if (window.__tirzPlotterNativeBridgeInstalled) return;
        if (!window.TirzPlotterDownloads || !window.TirzPlotterImports) return;

        window.__tirzPlotterNativeBridgeInstalled = true;
        if (typeof window.exportJSON === 'function') {
          window.__tirzPlotterOriginalExportJSON = window.exportJSON;
          window.exportJSON = function () {
            try {
              var storageKey = '$_storageKey';
              var raw = localStorage.getItem(storageKey) || '[]';
              var records = JSON.parse(raw);
              if (!Array.isArray(records) || records.length === 0) {
                alert('No data to export.');
                return;
              }

              var dateStr = new Date().toISOString().split('T')[0];
              window.TirzPlotterDownloads.postMessage(JSON.stringify({
                filename: 'tirzepatide-doses-' + dateStr + '.json',
                contents: JSON.stringify(records, null, 2)
              }));
            } catch (error) {
              window.__tirzPlotterOriginalExportJSON();
            }
          };
        }

        if (typeof window.triggerImport === 'function') {
          window.__tirzPlotterOriginalTriggerImport = window.triggerImport;
          window.triggerImport = function () {
            window.TirzPlotterImports.postMessage('import');
          };
        }
      })();
    ''');
  }

  Future<void> _saveExport(JavaScriptMessage message) async {
    try {
      final payload = jsonDecode(message.message) as Map<String, dynamic>;
      final filename = payload['filename'] as String? ?? _defaultExportFilename;
      final contents = payload['contents'] as String? ?? '[]';

      final savedPath = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        {'filename': filename, 'contents': contents},
      );
      if (!mounted) return;
      _showSnackBar('Saved export to ${savedPath ?? filename}');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Export failed. Please try again.');
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final text = utf8.decode(await _readPickedFile(result.files.single));
      final payload = jsonDecode(text);
      if (payload is! List) {
        throw const FormatException('Expected an array of dose records.');
      }

      final encoded = jsonEncode(payload);
      await _controller.runJavaScript('''
        (function () {
          var imported = ${jsonEncode(encoded)};
          localStorage.setItem('$_storageKey', imported);
          location.reload();
        })();
      ''');

      if (!mounted) return;
      final noun = payload.length == 1 ? 'injection' : 'injections';
      _showSnackBar('Imported ${payload.length} $noun');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Import failed. Choose a valid TirzPlotter JSON export.');
    }
  }

  Future<List<int>> _readPickedFile(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null) return File(file.path!).readAsBytes();
    throw StateError('Could not read selected file.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (!_pageLoaded && _error == null) const _LoadingView(),
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                minHeight: 2,
              ),
            if (_error != null) _ErrorView(message: _error!, onRetry: _reload),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xff0a0f1a),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, color: Color(0xff60a5fa), size: 46),
            SizedBox(height: 14),
            Text('TirzPlotter',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Loading estimator...',
                style: TextStyle(color: Color(0xff94a3b8))),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff0a0f1a),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 42, color: Color(0xff64748b)),
              const SizedBox(height: 16),
              const Text('TirzPlotter could not load',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xff94a3b8))),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
