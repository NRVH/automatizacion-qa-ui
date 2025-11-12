// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateInfo _$UpdateInfoFromJson(Map<String, dynamic> json) => UpdateInfo(
  version: json['version'] as String,
  downloadUrl: json['downloadUrl'] as String,
  releaseUrl: json['releaseUrl'] as String,
  changelog: json['changelog'] as String,
  releaseDate: DateTime.parse(json['releaseDate'] as String),
  downloadSize: (json['downloadSize'] as num).toInt(),
  isMandatory: json['isMandatory'] as bool? ?? false,
);

Map<String, dynamic> _$UpdateInfoToJson(UpdateInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'downloadUrl': instance.downloadUrl,
      'releaseUrl': instance.releaseUrl,
      'changelog': instance.changelog,
      'releaseDate': instance.releaseDate.toIso8601String(),
      'downloadSize': instance.downloadSize,
      'isMandatory': instance.isMandatory,
    };
