import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Conditional import for non-web platforms
import 'dart:io' show Platform
  if (dart.library.js_interop) 'dart:io';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  /// Comprehensive device information collection
  Future<Map<String, dynamic>> collectAllDeviceInfo(BuildContext? context) async {
    if (kDebugMode) {
      print('\n${'=' * 80}');
      print('🔍 COMPREHENSIVE DEVICE INFORMATION COLLECTION STARTED');
      print('=' * 80);
    }

    try {
      tz.initializeTimeZones();
      
      final deviceInfo = <String, dynamic>{};
      final startTime = DateTime.now();

      // Collect all information in parallel where possible
      final futures = await Future.wait([
        _collectHardwareInfo(),
        _collectSoftwareInfo(),
        _collectNetworkInfo(),
        _collectAppInfo(),
        _collectSensorInfo(),
        _collectBatteryInfo(),
        _collectScreenInfo(context),
        _collectLocationInfo(),
        _collectSecurityInfo(),
      ]);

      deviceInfo['hardware'] = futures[0];
      deviceInfo['software'] = futures[1];
      deviceInfo['network'] = futures[2];
      deviceInfo['app'] = futures[3];
      deviceInfo['sensors'] = futures[4];
      deviceInfo['battery'] = futures[5];
      deviceInfo['screen'] = futures[6];
      deviceInfo['location'] = futures[7];
      deviceInfo['security'] = futures[8];

      final endTime = DateTime.now();
      deviceInfo['collection_metadata'] = {
        'timestamp': DateTime.now().toIso8601String(),
        'collection_time_ms': endTime.difference(startTime).inMilliseconds,
        'platform': _getPlatformName(),
        'flutter_version': _getFlutterVersion(),
      };

      if (kDebugMode) {
        _printFormattedDeviceInfo(deviceInfo);
      }
      return deviceInfo;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error collecting device information: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Hardware & Device Information
  Future<Map<String, dynamic>> _collectHardwareInfo() async {
    final hardware = <String, dynamic>{};

    try {
      if (kIsWeb) {
        hardware.addAll(await _collectWebHardware());
      } else if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          hardware.addAll(_extractAndroidHardware(androidInfo));
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          hardware.addAll(_extractIOSHardware(iosInfo));
        } else if (Platform.isWindows) {
          final windowsInfo = await _deviceInfo.windowsInfo;
          hardware.addAll(_extractWindowsHardware(windowsInfo));
        } else if (Platform.isMacOS) {
          final macInfo = await _deviceInfo.macOsInfo;
          hardware.addAll(_extractMacOSHardware(macInfo));
        } else if (Platform.isLinux) {
          final linuxInfo = await _deviceInfo.linuxInfo;
          hardware.addAll(_extractLinuxHardware(linuxInfo));
        }
      }
    } catch (e) {
      hardware['error'] = e.toString();
    }

    return hardware;
  }

  /// Web Hardware Info (simplified for web compatibility)
  Future<Map<String, dynamic>> _collectWebHardware() async {
    final webHardware = <String, dynamic>{};
    
    try {
      final webInfo = await _deviceInfo.webBrowserInfo;
      webHardware['browser_name'] = webInfo.browserName.toString().split('.').last;
      webHardware['app_code_name'] = webInfo.appCodeName;
      webHardware['app_name'] = webInfo.appName;
      webHardware['app_version'] = webInfo.appVersion;
      webHardware['device_memory'] = webInfo.deviceMemory;
      webHardware['language'] = webInfo.language;
      webHardware['languages'] = webInfo.languages;
      webHardware['platform'] = webInfo.platform;
      webHardware['product'] = webInfo.product;
      webHardware['product_sub'] = webInfo.productSub;
      webHardware['user_agent'] = webInfo.userAgent;
      webHardware['vendor'] = webInfo.vendor;
      webHardware['vendor_sub'] = webInfo.vendorSub;
      webHardware['hardware_concurrency'] = webInfo.hardwareConcurrency;
      webHardware['max_touch_points'] = webInfo.maxTouchPoints;
    } catch (e) {
      webHardware['error'] = e.toString();
    }

    return webHardware;
  }

  Map<String, dynamic> _extractAndroidHardware(AndroidDeviceInfo info) {
    return {
      'brand': info.brand,
      'device': info.device,
      'display': info.display,
      'hardware': info.hardware,
      'host': info.host,
      'id': info.id,
      'manufacturer': info.manufacturer,
      'model': info.model,
      'product': info.product,
      'supported_abis': info.supportedAbis,
      'supported_32bit_abis': info.supported32BitAbis,
      'supported_64bit_abis': info.supported64BitAbis,
      'tags': info.tags,
      'type': info.type,
      'board': info.board,
      'bootloader': info.bootloader,
      'fingerprint': info.fingerprint,
      'physical_device': info.isPhysicalDevice,
      'android_version': info.version.release,
      'android_sdk': info.version.sdkInt,
      'security_patch': info.version.securityPatch,
    };
  }

  Map<String, dynamic> _extractIOSHardware(IosDeviceInfo info) {
    return {
      'name': info.name,
      'system_name': info.systemName,
      'system_version': info.systemVersion,
      'model': info.model,
      'localized_model': info.localizedModel,
      'identifier_for_vendor': info.identifierForVendor,
      'physical_device': info.isPhysicalDevice,
      'utsname_sysname': info.utsname.sysname,
      'utsname_nodename': info.utsname.nodename,
      'utsname_release': info.utsname.release,
      'utsname_version': info.utsname.version,
      'utsname_machine': info.utsname.machine,
    };
  }

  Map<String, dynamic> _extractWindowsHardware(WindowsDeviceInfo info) {
    try {
      return {
        'computer_name': info.computerName,
        'number_of_cores': info.numberOfCores,
        'system_memory_in_megabytes': info.systemMemoryInMegabytes,
        'user_name': info.userName,
        'major_version': info.majorVersion,
        'minor_version': info.minorVersion,
        'build_number': info.buildNumber,
        'platform_id': info.platformId,
        'csd_version': info.csdVersion,
        'service_pack_major': info.servicePackMajor,
        'service_pack_minor': info.servicePackMinor,
        'product_type': info.productType,
        'device_id': info.deviceId,
        'product_name': info.productName,
        'display_version': info.displayVersion,
        'release_id': info.releaseId,
        'install_date': info.installDate?.toString(),
      };
    } catch (e) {
      return {
        'error': 'Failed to extract Windows hardware info: $e',
        'computer_name': info.computerName,
        'number_of_cores': info.numberOfCores,
        'system_memory_in_megabytes': info.systemMemoryInMegabytes,
      };
    }
  }

  Map<String, dynamic> _extractMacOSHardware(MacOsDeviceInfo info) {
    try {
      return {
        'computer_name': info.computerName,
        'host_name': info.hostName,
        'arch': info.arch,
        'model': info.model,
        'kernel_version': info.kernelVersion,
        'major_version': info.majorVersion,
        'minor_version': info.minorVersion,
        'patch_version': info.patchVersion,
        'os_release': info.osRelease,
        'active_cpus': info.activeCPUs,
        'memory_size': info.memorySize,
        'cpu_frequency': info.cpuFrequency,
        'system_guid': info.systemGUID,
      };
    } catch (e) {
      return {
        'error': 'Failed to extract macOS hardware info: $e',
        'computer_name': info.computerName,
        'arch': info.arch,
        'model': info.model,
      };
    }
  }

  Map<String, dynamic> _extractLinuxHardware(LinuxDeviceInfo info) {
    try {
      return {
        'name': info.name,
        'version': info.version,
        'id': info.id,
        'id_like': info.idLike,
        'version_codename': info.versionCodename,
        'version_id': info.versionId,
        'pretty_name': info.prettyName,
        'build_id': info.buildId,
        'variant': info.variant,
        'variant_id': info.variantId,
        'machine_id': info.machineId,
      };
    } catch (e) {
      return {
        'error': 'Failed to extract Linux hardware info: $e',
        'name': info.name,
        'version': info.version,
        'id': info.id,
      };
    }
  }

  /// Software & OS Information
  Future<Map<String, dynamic>> _collectSoftwareInfo() async {
    final software = <String, dynamic>{};

    try {
      software['platform'] = _getPlatformName();
      software['is_web'] = kIsWeb;
      software['is_debug_mode'] = kDebugMode;
      software['is_profile_mode'] = kProfileMode;
      software['is_release_mode'] = kReleaseMode;
      
      if (!kIsWeb) {
        software['dart_version'] = Platform.version;
        software['operating_system'] = Platform.operatingSystem;
        software['operating_system_version'] = Platform.operatingSystemVersion;
        software['locale_name'] = Platform.localeName;
        software['host_name'] = Platform.localHostname;
        software['number_of_processors'] = Platform.numberOfProcessors;
        software['path_separator'] = Platform.pathSeparator;
        software['executable'] = Platform.executable;
        software['resolved_executable'] = Platform.resolvedExecutable;
        software['script'] = Platform.script.toString();
        software['environment_variables'] = Platform.environment.keys.take(10).toList(); // Limit for privacy
      }

      // Locale and language information using ui.PlatformDispatcher
      final view = ui.PlatformDispatcher.instance.views.first;
      final locale = view.platformDispatcher.locale;
      software['primary_locale'] = {
        'language_code': locale.languageCode,
        'country_code': locale.countryCode,
        'script_code': locale.scriptCode,
        'to_string': locale.toString(),
      };

      final locales = view.platformDispatcher.locales;
      software['all_locales'] = locales.map((l) => {
        'language_code': l.languageCode,
        'country_code': l.countryCode,
        'script_code': l.scriptCode,
        'to_string': l.toString(),
      }).take(10).toList(); // Limit output

      // Date/Time formatting
      software['date_formatting'] = {
        'current_time': DateTime.now().toString(),
        'current_time_utc': DateTime.now().toUtc().toString(),
        'current_time_iso': DateTime.now().toIso8601String(),
        'formatted_date': DateFormat.yMMMd().format(DateTime.now()),
        'formatted_time': DateFormat.Hms().format(DateTime.now()),
        'timezone': DateTime.now().timeZoneName,
        'timezone_offset': DateTime.now().timeZoneOffset.toString(),
      };

    } catch (e) {
      software['error'] = e.toString();
    }

    return software;
  }

  /// Network Information
  Future<Map<String, dynamic>> _collectNetworkInfo() async {
    final network = <String, dynamic>{};

    try {
      // Connectivity status
      final connectivityResults = await _connectivity.checkConnectivity();
      network['connectivity_results'] = connectivityResults.map((c) => c.toString().split('.').last).toList();

      // Get IP information
      network['ip_info'] = await _getIPInformation();

    } catch (e) {
      network['error'] = e.toString();
    }

    return network;
  }

  Future<Map<String, dynamic>> _getIPInformation() async {
    try {
      // Try multiple IP services
      final services = [
        'https://api.ipify.org?format=json',
        'https://httpbin.org/ip',
        'https://ipinfo.io/json',
      ];

      for (final service in services) {
        try {
          final response = await http.get(Uri.parse(service)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return {
              'service_used': service,
              'data': data,
            };
          }
        } catch (e) {
          continue;
        }
      }
      
      return {'error': 'All IP services failed'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// App Information
  Future<Map<String, dynamic>> _collectAppInfo() async {
    final app = <String, dynamic>{};

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      app['app_name'] = packageInfo.appName;
      app['package_name'] = packageInfo.packageName;
      app['version'] = packageInfo.version;
      app['build_number'] = packageInfo.buildNumber;
      app['build_signature'] = packageInfo.buildSignature;
      app['installer_store'] = packageInfo.installerStore;
    } catch (e) {
      app['error'] = e.toString();
    }

    return app;
  }

  /// Sensor Information
  Future<Map<String, dynamic>> _collectSensorInfo() async {
    final sensors = <String, dynamic>{};

    try {
      sensors['platform_supports_sensors'] = !kIsWeb;

      if (!kIsWeb) {
        // Try to get a single reading from each sensor (with timeout) using new APIs
        try {
          final accelEvent = await accelerometerEventStream().first.timeout(const Duration(seconds: 2));
          sensors['accelerometer_sample'] = {
            'x': accelEvent.x,
            'y': accelEvent.y,
            'z': accelEvent.z,
          };
          sensors['accelerometer_available'] = true;
        } catch (e) {
          sensors['accelerometer_sample'] = 'Not available or timeout';
          sensors['accelerometer_available'] = false;
        }

        try {
          final gyroEvent = await gyroscopeEventStream().first.timeout(const Duration(seconds: 2));
          sensors['gyroscope_sample'] = {
            'x': gyroEvent.x,
            'y': gyroEvent.y,
            'z': gyroEvent.z,
          };
          sensors['gyroscope_available'] = true;
        } catch (e) {
          sensors['gyroscope_sample'] = 'Not available or timeout';
          sensors['gyroscope_available'] = false;
        }

        try {
          final magnetEvent = await magnetometerEventStream().first.timeout(const Duration(seconds: 2));
          sensors['magnetometer_sample'] = {
            'x': magnetEvent.x,
            'y': magnetEvent.y,
            'z': magnetEvent.z,
          };
          sensors['magnetometer_available'] = true;
        } catch (e) {
          sensors['magnetometer_sample'] = 'Not available or timeout';
          sensors['magnetometer_available'] = false;
        }
      } else {
        sensors['note'] = 'Sensor access not available on web platform';
      }

    } catch (e) {
      sensors['error'] = e.toString();
    }

    return sensors;
  }

  /// Battery Information
  Future<Map<String, dynamic>> _collectBatteryInfo() async {
    final battery = <String, dynamic>{};

    try {
      battery['battery_level'] = await _battery.batteryLevel;
      battery['battery_state'] = (await _battery.batteryState).toString();
      battery['is_in_battery_save_mode'] = await _battery.isInBatterySaveMode;
    } catch (e) {
      battery['error'] = e.toString();
    }

    return battery;
  }

  /// Screen Information
  Future<Map<String, dynamic>> _collectScreenInfo(BuildContext? context) async {
    final screen = <String, dynamic>{};

    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      screen['device_pixel_ratio'] = view.devicePixelRatio;
      screen['physical_size'] = {
        'width': view.physicalSize.width,
        'height': view.physicalSize.height,
      };
      
      if (context != null) {
        final mediaQuery = MediaQuery.of(context);
        screen['logical_size'] = {
          'width': mediaQuery.size.width,
          'height': mediaQuery.size.height,
        };
        screen['padding'] = {
          'top': mediaQuery.padding.top,
          'bottom': mediaQuery.padding.bottom,
          'left': mediaQuery.padding.left,
          'right': mediaQuery.padding.right,
        };
        screen['safe_area'] = {
          'top': mediaQuery.viewPadding.top,
          'bottom': mediaQuery.viewPadding.bottom,
          'left': mediaQuery.viewPadding.left,
          'right': mediaQuery.viewPadding.right,
        };
        screen['text_scaler'] = mediaQuery.textScaler.toString();
        screen['platform_brightness'] = mediaQuery.platformBrightness.toString();
        screen['orientation'] = mediaQuery.orientation.toString();
        screen['accessible_navigation'] = mediaQuery.accessibleNavigation;
        screen['invert_colors'] = mediaQuery.invertColors;
        screen['high_contrast'] = mediaQuery.highContrast;
        screen['disable_animations'] = mediaQuery.disableAnimations;
        screen['bold_text'] = mediaQuery.boldText;
      }

    } catch (e) {
      screen['error'] = e.toString();
    }

    return screen;
  }

  /// Location/Timezone Information
  Future<Map<String, dynamic>> _collectLocationInfo() async {
    final location = <String, dynamic>{};

    try {
      tz.initializeTimeZones();
      
      location['current_timezone'] = DateTime.now().timeZoneName;
      location['current_timezone_offset'] = DateTime.now().timeZoneOffset.toString();
      
      // Sample some key timezones
      try {
        final seoul = tz.getLocation('Asia/Seoul');
        final newYork = tz.getLocation('America/New_York');
        final utc = tz.UTC;
        
        location['sample_timezones'] = {
          'seoul_now': tz.TZDateTime.now(seoul).toString(),
          'new_york_now': tz.TZDateTime.now(newYork).toString(),
          'utc_now': tz.TZDateTime.now(utc).toString(),
        };
      } catch (e) {
        location['timezone_samples_error'] = e.toString();
      }
      
      if (!kIsWeb) {
        location['system_locale'] = Platform.localeName;
      }
      
    } catch (e) {
      location['error'] = e.toString();
    }

    return location;
  }

  /// Security Information
  Future<Map<String, dynamic>> _collectSecurityInfo() async {
    final security = <String, dynamic>{};

    try {
      if (kIsWeb) {
        security['is_web_platform'] = true;
        security['https_note'] = 'HTTPS status available via browser APIs in web-specific implementation';
      } else {
        security['is_web_platform'] = false;
        security['platform_security_note'] = 'Mobile security checks require platform-specific implementation';
      }

      security['debug_mode'] = kDebugMode;
      security['profile_mode'] = kProfileMode;
      security['release_mode'] = kReleaseMode;

    } catch (e) {
      security['error'] = e.toString();
    }

    return security;
  }

  /// Helper methods
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (!kIsWeb) {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isFuchsia) return 'Fuchsia';
    }
    return 'Unknown';
  }

  String _getFlutterVersion() {
    if (!kIsWeb) {
      return 'Flutter ${Platform.version}';
    }
    return 'Flutter Web';
  }

  /// Print formatted device information
  void _printFormattedDeviceInfo(Map<String, dynamic> deviceInfo) {
    if (!kDebugMode) return;

    print('\n🔍 DEVICE INFORMATION REPORT\n${'=' * 80}');
    
    // Collection metadata
    final metadata = deviceInfo['collection_metadata'] as Map<String, dynamic>;
    print('\n📊 COLLECTION METADATA');
    print('─' * 40);
    metadata.forEach((key, value) {
      print('  ${key.toUpperCase().replaceAll('_', ' ')}: $value');
    });

    // Hardware Information
    print('\n🔧 HARDWARE INFORMATION');
    print('─' * 40);
    final hardware = deviceInfo['hardware'] as Map<String, dynamic>;
    _printSection(hardware);

    // Software Information
    print('\n💻 SOFTWARE INFORMATION');
    print('─' * 40);
    final software = deviceInfo['software'] as Map<String, dynamic>;
    _printSection(software);

    // App Information
    print('\n📱 APP INFORMATION');
    print('─' * 40);
    final app = deviceInfo['app'] as Map<String, dynamic>;
    _printSection(app);

    // Screen Information
    print('\n📺 SCREEN INFORMATION');
    print('─' * 40);
    final screen = deviceInfo['screen'] as Map<String, dynamic>;
    _printSection(screen);

    // Network Information
    print('\n🌍 NETWORK INFORMATION');
    print('─' * 40);
    final network = deviceInfo['network'] as Map<String, dynamic>;
    _printSection(network);

    // Battery Information
    print('\n🔋 BATTERY INFORMATION');
    print('─' * 40);
    final battery = deviceInfo['battery'] as Map<String, dynamic>;
    _printSection(battery);

    // Sensor Information
    print('\n📡 SENSOR INFORMATION');
    print('─' * 40);
    final sensors = deviceInfo['sensors'] as Map<String, dynamic>;
    _printSection(sensors);

    // Location Information
    print('\n📍 LOCATION/TIMEZONE INFORMATION');
    print('─' * 40);
    final location = deviceInfo['location'] as Map<String, dynamic>;
    _printSection(location);

    // Security Information
    print('\n🔐 SECURITY INFORMATION');
    print('─' * 40);
    final security = deviceInfo['security'] as Map<String, dynamic>;
    _printSection(security);

    print('\n${'=' * 80}');
    print('✅ DEVICE INFORMATION COLLECTION COMPLETED');
    print('${'=' * 80}\n');
  }

  void _printSection(Map<String, dynamic> section, {int indent = 0}) {
    final prefix = '  ' * indent;
    section.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        print('$prefix${key.toUpperCase().replaceAll('_', ' ')}:');
        _printSection(value, indent: indent + 1);
      } else if (value is List) {
        print('$prefix${key.toUpperCase().replaceAll('_', ' ')}: [${value.length} items]');
        for (int i = 0; i < value.length && i < 5; i++) {
          print('$prefix  [$i]: ${value[i]}');
        }
        if (value.length > 5) {
          print('$prefix  ... and ${value.length - 5} more items');
        }
      } else {
        final displayValue = value.toString().length > 100 
          ? '${value.toString().substring(0, 100)}...'
          : value.toString();
        print('$prefix${key.toUpperCase().replaceAll('_', ' ')}: $displayValue');
      }
    });
  }
}