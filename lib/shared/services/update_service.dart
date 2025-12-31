import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Update Service for checking and downloading GitHub releases
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // GitHub repository info - UPDATE THESE WITH YOUR REPO
  static const String _githubOwner = 'workbhaveshpandey-create';
  static const String _githubRepo = 'kreo-calendar';

  String? _latestVersion;
  String? _downloadUrl;
  String? _releaseNotes;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Getters
  String? get latestVersion => _latestVersion;
  String? get downloadUrl => _downloadUrl;
  String? get releaseNotes => _releaseNotes;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  /// Get current app version
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Check for updates from GitHub releases
  Future<UpdateCheckResult> checkForUpdates() async {
    if (_isChecking) {
      return UpdateCheckResult(
        hasUpdate: false,
        error: 'Already checking for updates',
      );
    }

    _isChecking = true;

    try {
      final currentVersion = await getCurrentVersion();
      print('DEBUG: Current version: $currentVersion');

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] as String;
        // Remove 'v' prefix if present
        _latestVersion = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;
        _releaseNotes = data['body'] as String?;

        // Find APK asset
        final assets = data['assets'] as List<dynamic>;
        for (final asset in assets) {
          final name = asset['name'] as String;
          if (name.endsWith('.apk')) {
            _downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        print('DEBUG: Latest version: $_latestVersion');
        print('DEBUG: Download URL: $_downloadUrl');

        final hasUpdate = _compareVersions(currentVersion, _latestVersion!);

        _isChecking = false;
        return UpdateCheckResult(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: _latestVersion,
          releaseNotes: _releaseNotes,
          downloadUrl: _downloadUrl,
        );
      } else if (response.statusCode == 404) {
        _isChecking = false;
        return UpdateCheckResult(hasUpdate: false, error: 'No releases found');
      } else {
        _isChecking = false;
        return UpdateCheckResult(
          hasUpdate: false,
          error: 'Failed to check for updates (${response.statusCode})',
        );
      }
    } catch (e) {
      print('DEBUG: Update check error: $e');
      _isChecking = false;
      return UpdateCheckResult(
        hasUpdate: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Compare two version strings (returns true if latest > current)
  bool _compareVersions(String current, String latest) {
    // 1. Parse base version and build number
    // Format: "1.0.0+1" -> base: "1.0.0", build: 1

    final currentSemVer = _parseSemVer(current);
    final latestSemVer = _parseSemVer(latest);

    // 2. Compare base versions (Major.Minor.Patch)
    for (int i = 0; i < 3; i++) {
      if (latestSemVer.base[i] > currentSemVer.base[i]) return true;
      if (latestSemVer.base[i] < currentSemVer.base[i]) return false;
    }

    // 3. If base versions equal, compare build numbers
    return latestSemVer.build > currentSemVer.build;
  }

  /// Helper to parse version string into structured data
  _SemVer _parseSemVer(String version) {
    try {
      // Remove 'v' prefix if present
      final cleanVersion = version.startsWith('v')
          ? version.substring(1)
          : version;

      final parts = cleanVersion.split('+');
      final baseStr = parts[0];
      final buildStr = parts.length > 1 ? parts[1] : '0';

      final baseParts = baseStr
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      while (baseParts.length < 3) baseParts.add(0);

      return _SemVer(base: baseParts, build: int.tryParse(buildStr) ?? 0);
    } catch (e) {
      // Fallback for malformed versions
      return _SemVer(base: [0, 0, 0], build: 0);
    }
  }

  /// Download and install the APK update
  Future<void> downloadAndInstall({
    required String url,
    Function(double)? onProgress,
    Function(String)? onError,
    Function()? onComplete,
  }) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/kreo_calendar_update.apk';
      final file = File(filePath);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final contentLength = response.contentLength ?? 0;
      int receivedBytes = 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = receivedBytes / contentLength;
          onProgress?.call(_downloadProgress);
        }
      }

      await file.writeAsBytes(bytes);
      client.close();

      _isDownloading = false;
      _downloadProgress = 1.0;

      // Open APK for installation
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        onError?.call('Could not open APK: ${result.message}');
      } else {
        onComplete?.call();
      }
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      onError?.call('Download failed: ${e.toString()}');
    }
  }
}

class _SemVer {
  final List<int> base;
  final int build;
  _SemVer({required this.base, required this.build});
}

/// Result of an update check
class UpdateCheckResult {
  final bool hasUpdate;
  final String? currentVersion;
  final String? latestVersion;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? error;

  UpdateCheckResult({
    required this.hasUpdate,
    this.currentVersion,
    this.latestVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.error,
  });
}
