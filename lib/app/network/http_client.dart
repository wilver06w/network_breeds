import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:l10n_breeds/generated/l10n.dart';
import 'package:network_breeds/app/network/dio.dart';
import 'package:network_breeds/app/network/http_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utils_breeds/utils/config/client_config.dart';
import 'package:utils_breeds/utils/config/environment.dart';

export 'package:dio/dio.dart';
export 'package:flutter_modular/flutter_modular.dart';

class XigoHttpClient {
  XigoHttpClient._();
  static final _singleton = XigoHttpClient._();

  factory XigoHttpClient() => _singleton;

  static Environment env = Environment.dev;
  late XigoSharedDio _msDio;

  late String _deviceVersion;
  late String _appVersion;
  late String _userAgent;

  Dio get msDio => _msDio.dio;
  XigoSharedDio get xigoSharedDio => _msDio;

  Future<void> initAsyncData() async {
    _singleton._deviceVersion = await _getDeviceVersion();
    _singleton._appVersion = await _getAppVersion();
    _singleton._userAgent = await _getUserAgent();
  }

  XigoHttpClient getInstance(AppConfig config) {
    _singleton._msDio = XigoSharedDio(
      baseUrl: config.country.api!,
      appName: 'app-breeds',
      interceptors: [],
      appVersion: _singleton._appVersion,
      countryCode: config.country.locale?.countryCode ?? '',
      langCode: config.country.locale?.languageCode ?? '',
      os: _getOsName(),
      userAgent: _singleton._userAgent,
      deviceVersion: _singleton._deviceVersion,
      enableLogs: env != Environment.prod,
    );

    S.load(
      Locale(
        config.country.locale!.languageCode!,
        config.country.locale!.countryCode!,
      ),
    );

    updateDeviceHeaders();
    _addHeaderXsource();
    return _singleton;
  }

  void updateDeviceHeaders() {
    final headers = {
      'x-api-key': 'bda53789-d59e-46cd-9bc4-2936630fde39',
    };
    _msDio.addHeaders(headers);
  }

  String _getOsName() {
    return Platform.isIOS ? 'ios' : 'android';
  }

  Future<String> _getDeviceVersion() async {
    final deviceOSversion = Platform.isIOS
        ? (await DeviceInfoPlugin().iosInfo).systemVersion
        : (await DeviceInfoPlugin().androidInfo).version.release;
    return deviceOSversion;
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> _getUserAgent() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final dartFullVersion = Platform.version;
    final dartShortVersion = dartFullVersion.split(' ')[0];
    final os = _getOsName();
    final deviceOSversion = await _getDeviceVersion();
    return 'Dart/$dartShortVersion - Breed/${packageInfo.version} - OS/$os - Version/$deviceOSversion';
  }

  void _addHeaderXsource() {
    const source = String.fromEnvironment('x-source');
    if (source.isNotEmpty) {
      _msDio.addHeaders({
        "X-source": source,
      });
    }
  }
}
