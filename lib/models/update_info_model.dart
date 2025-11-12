import 'package:json_annotation/json_annotation.dart';

part 'update_info_model.g.dart';

/// Información de una actualización disponible
@JsonSerializable()
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseUrl;
  final String changelog;
  final DateTime releaseDate;
  final int downloadSize;
  final bool isMandatory;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.changelog,
    required this.releaseDate,
    required this.downloadSize,
    this.isMandatory = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$UpdateInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateInfoToJson(this);

  /// Convierte desde la respuesta de GitHub API
  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> githubData) {
    final assets = githubData['assets'] as List;
    final zipAsset = assets.firstWhere(
      (asset) => (asset['name'] as String).endsWith('.zip'),
      orElse: () => assets.first,
    );

    return UpdateInfo(
      version: (githubData['tag_name'] as String).replaceAll('v', ''),
      downloadUrl: zipAsset['browser_download_url'] as String,
      releaseUrl: githubData['html_url'] as String,
      changelog: githubData['body'] as String? ?? 'Sin notas de la versión',
      releaseDate: DateTime.parse(githubData['published_at'] as String),
      downloadSize: zipAsset['size'] as int? ?? 0,
      isMandatory: (githubData['body'] as String? ?? '')
          .toLowerCase()
          .contains('[mandatory]'),
    );
  }

  /// Formatea el tamaño de descarga de forma legible
  String get formattedSize {
    if (downloadSize == 0) return 'Desconocido';
    
    if (downloadSize < 1024) return '$downloadSize B';
    if (downloadSize < 1024 * 1024) {
      return '${(downloadSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formatea la fecha de lanzamiento
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(releaseDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${releaseDate.day}/${releaseDate.month}/${releaseDate.year}';
    }
  }
}
