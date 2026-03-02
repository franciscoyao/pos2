import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository.g.dart';

class SettingsModel {
  final String id;
  final double taxRate;
  final double serviceRate;
  final String currencySymbol;
  final bool kioskMode;
  final int orderDelayThreshold;

  SettingsModel({
    required this.id,
    required this.taxRate,
    required this.serviceRate,
    required this.currencySymbol,
    required this.kioskMode,
    required this.orderDelayThreshold,
  });
}

// Settings repository with local defaults (backend doesn't have settings API yet)
class SettingsRepository {
  SettingsRepository();

  Future<SettingsModel?> getSettings() async {
    // Return default settings
    return SettingsModel(
      id: 'default',
      taxRate: 10.0,
      serviceRate: 5.0,
      currencySymbol: '\$',
      kioskMode: false,
      orderDelayThreshold: 15,
    );
  }

  Future<SettingsModel> updateSettings({
    required double taxRate,
    required double serviceRate,
    required String currencySymbol,
    required bool kioskMode,
    required int orderDelayThreshold,
  }) async {
    debugPrint('Settings update not implemented in backend yet');
    return SettingsModel(
      id: 'default',
      taxRate: taxRate,
      serviceRate: serviceRate,
      currencySymbol: currencySymbol,
      kioskMode: kioskMode,
      orderDelayThreshold: orderDelayThreshold,
    );
  }

  Future<SettingsModel> initSettings() async {
    return getSettings().then((s) => s!);
  }
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository();
}
