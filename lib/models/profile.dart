import 'dart:io';
import 'dart:typed_data';

import 'package:flclashx/common/common.dart';
import 'package:flclashx/core/controller.dart';
import 'package:flclashx/enum/enum.dart';
import 'package:flclashx/utils/device_info_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clash_config.dart';

part 'generated/profile.freezed.dart';
part 'generated/profile.g.dart';

@freezed
abstract class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    @Default(0) int upload,
    @Default(0) int download,
    @Default(0) int total,
    @Default(0) int expire,
  }) = _SubscriptionInfo;

  factory SubscriptionInfo.fromJson(Map<String, Object?> json) =>
      _$SubscriptionInfoFromJson(json);

  factory SubscriptionInfo.formHString(String? info) {
    if (info == null) return const SubscriptionInfo();
    final list = info.split(';');
    final Map<String, int?> map = {};
    for (final i in list) {
      final keyValue = i.trim().split('=');
      map[keyValue[0]] = int.tryParse(keyValue[1]);
    }
    return SubscriptionInfo(
      upload: map['upload'] ?? 0,
      download: map['download'] ?? 0,
      total: map['total'] ?? 0,
      expire: map['expire'] ?? 0,
    );
  }
}

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required int id,
    @Default('') String label,
    String? currentGroupName,
    @Default('') String url,
    DateTime? lastUpdateDate,
    required Duration autoUpdateDuration,
    SubscriptionInfo? subscriptionInfo,
    @Default(true) bool autoUpdate,
    @Default({}) Map<String, String> selectedMap,
    @Default({}) Set<String> unfoldSet,
    @Default(OverwriteType.standard) OverwriteType overwriteType,
    int? scriptId,
    int? order,
    @Default({}) Map<String, String> providerHeaders,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);

  factory Profile.normal({String? label, String url = ''}) {
    final id = snowflake.id;
    return Profile(
      label: label ?? '',
      url: url,
      id: id,
      autoUpdateDuration: defaultUpdateDuration,
    );
  }
}

@freezed
abstract class ProfileRuleLink with _$ProfileRuleLink {
  const factory ProfileRuleLink({
    int? profileId,
    required int ruleId,
    RuleScene? scene,
    String? order,
  }) = _ProfileRuleLink;
}

extension ProfileRuleLinkExt on ProfileRuleLink {
  String get key {
    final splits = <String?>[
      profileId?.toString(),
      ruleId.toString(),
      scene?.name,
    ];
    return splits.where((item) => item != null).join('_');
  }
}

// @freezed
// abstract class Overwrite with _$Overwrite {
//   const factory Overwrite({
//     @Default(OverwriteType.standard) OverwriteType type,
//     @Default(StandardOverwrite()) StandardOverwrite standardOverwrite,
//     @Default(ScriptOverwrite()) ScriptOverwrite scriptOverwrite,
//   }) = _Overwrite;
//
//   factory Overwrite.fromJson(Map<String, Object?> json) =>
//       _$OverwriteFromJson(json);
// }

@freezed
abstract class StandardOverwrite with _$StandardOverwrite {
  const factory StandardOverwrite({
    @Default([]) List<Rule> addedRules,
    @Default([]) List<int> disabledRuleIds,
  }) = _StandardOverwrite;

  factory StandardOverwrite.fromJson(Map<String, Object?> json) =>
      _$StandardOverwriteFromJson(json);
}

@freezed
abstract class ScriptOverwrite with _$ScriptOverwrite {
  const factory ScriptOverwrite({int? scriptId}) = _ScriptOverwrite;

  factory ScriptOverwrite.fromJson(Map<String, Object?> json) =>
      _$ScriptOverwriteFromJson(json);
}

extension ProfilesExt on List<Profile> {
  Profile? getProfile(int? profileId) {
    final index = indexWhere((profile) => profile.id == profileId);
    return index == -1 ? null : this[index];
  }

  String _getLabel(String label, int id) {
    final realLabel = label.takeFirstValid([id.toString()]);
    final hasDup =
        indexWhere(
          (element) => element.label == realLabel && element.id != id,
        ) !=
        -1;
    if (hasDup) {
      return _getLabel(utils.getOverwriteLabel(realLabel), id);
    } else {
      return label;
    }
  }

  Profile optimizeLabel(Profile profile) {
    return profile.copyWith(label: _getLabel(profile.label, profile.id));
  }
}

extension ProfileExtension on Profile {
  ProfileType get type =>
      url.isEmpty == true ? ProfileType.file : ProfileType.url;

  bool get realAutoUpdate => url.isEmpty == true ? false : autoUpdate;

  String get realLabel => label.takeFirstValid([id.toString()]);

  String get fileName => '$id.yaml';

  String get updatingKey => 'profile_$id';

  Future<Profile?> checkAndUpdateAndCopy() async {
    final mFile = await _getFile(false);
    final isExists = await mFile.exists();
    if (isExists || url.isEmpty) {
      return null;
    }
    return update();
  }

  Future<File> _getFile([bool autoCreate = true]) async {
    final path = await appPath.getProfilePath(id.toString());
    final file = File(path);
    final isExists = await file.exists();
    if (!isExists && autoCreate) {
      return file.create(recursive: true);
    }
    return file;
    // final oldPath = await appPath.getProfilePath(id);
    // final newPath = await appPath.getProfilePath(fileName);
    // final oldFile = oldPath == newPath ? null : File(oldPath);
    // final oldIsExists = await oldFile?.exists() ?? false;
    // if (oldIsExists) {
    //   return await oldFile!.rename(newPath);
    // }
    // final file = File(newPath);
    // final isExists = await file.exists();
    // if (!isExists && autoCreate) {
    //   return await file.create(recursive: true);
    // }
    // return file;
  }

  Future<File> get file async {
    return _getFile();
  }

  Future<Profile> update() async {
    final prefs = await SharedPreferences.getInstance();
    final sendDeviceHeaders = prefs.getBool('sendDeviceHeaders') ?? true;
    final headers = <String, dynamic>{};
    if (sendDeviceHeaders) {
      try {
        final deviceInfoService = DeviceInfoService();
        final details = await deviceInfoService.getDeviceDetails();
        if (details.hwid != null) headers['x-hwid'] = details.hwid;
        if (details.os != null) headers['x-device-os'] = details.os;
        if (details.osVersion != null) {
          headers['x-ver-os'] = details.osVersion;
        }
        if (details.model != null) headers['x-device-model'] = details.model;
      } catch (_) {}
    }
    final response = await request.getFileResponseForUrl(
      url,
      headers: headers.isNotEmpty ? headers : null,
    );
    final disposition = response.headers.value('content-disposition');
    final userinfo = response.headers.value('subscription-userinfo');

    final providerHeaders = <String, String>{};
    const headersToCollect = [
      'announce',
      'support-url',
      'profile-update-interval',
      'x-hwid-limit',
    ];
    for (final headerName in headersToCollect) {
      final value = response.headers.value(headerName);
      if (value != null && value.isNotEmpty) {
        providerHeaders[headerName] = value;
      }
    }
    response.headers.forEach((name, values) {
      if (name.toLowerCase().startsWith('flclashx-') && values.isNotEmpty) {
        providerHeaders[name.toLowerCase()] = values.first;
      }
    });

    Duration? durationFromHeader;
    final updateIntervalHeader = providerHeaders['profile-update-interval'];
    if (updateIntervalHeader != null) {
      final hours = int.tryParse(updateIntervalHeader);
      if (hours != null && hours > 0) {
        durationFromHeader = Duration(hours: hours);
      }
    }

    return copyWith(
      label: label.takeFirstValid([
        utils.getFileNameForDisposition(disposition),
        id.toString(),
      ]),
      subscriptionInfo: SubscriptionInfo.formHString(userinfo),
      autoUpdateDuration: durationFromHeader ?? autoUpdateDuration,
      providerHeaders: providerHeaders,
    ).saveFile(response.data ?? Uint8List.fromList([]));
  }

  Future<Profile> saveFile(Uint8List bytes) async {
    final path = await appPath.tempFilePath;
    final tempFile = File(path);
    await tempFile.safeWriteAsBytes(bytes);
    final message = await coreController.validateConfig(path);
    if (message.isNotEmpty) {
      throw message;
    }
    final mFile = await file;
    await tempFile.copy(mFile.path);
    await tempFile.safeDelete();
    return copyWith(lastUpdateDate: DateTime.now());
  }

  Future<Profile> saveFileWithPath(String path) async {
    final message = await coreController.validateConfig(path);
    if (message.isNotEmpty) {
      throw message;
    }
    final mFile = await file;
    await File(path).copy(mFile.path);
    return copyWith(lastUpdateDate: DateTime.now());
  }
}
