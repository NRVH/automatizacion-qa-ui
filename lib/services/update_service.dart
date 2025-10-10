import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/update_info_model.dart';
import '../constants/app_constants.dart';

class UpdateService {
  static const String githubRepo = 'NRVH/automatizacion-qa-ui';
  static const String currentVersion = AppConstants.appVersion;

  /// Verifica si hay actualizaciones disponibles
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final url = 'https://api.github.com/repos/$githubRepo/releases/latest';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromGitHubRelease(data);

        // Verificar si es una versión más nueva
        if (_isNewerVersion(updateInfo.version, currentVersion)) {
          return updateInfo;
        }
      } else if (response.statusCode == 404) {
        // No hay releases aún
        return null;
      } else {
        print('Error al verificar actualizaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al verificar actualizaciones: $e');
    }
    return null;
  }

  /// Compara dos versiones (formato: x.y.z)
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // Asegurar que ambas tengan 3 partes
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      print('Error comparando versiones: $e');
      return false;
    }
  }

  /// Descarga e instala la actualización
  Future<void> downloadAndInstall({
    required UpdateInfo updateInfo,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    try {
      onStatus('Descargando actualización...');

      // Obtener ruta del ejecutable actual
      final exePath = Platform.resolvedExecutable;
      final exeDir = path.dirname(exePath);
      final tempDir = Directory(path.join(exeDir, 'temp_update'));

      // Crear directorio temporal
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      // Descargar el archivo ZIP
      final zipPath = path.join(tempDir.path, 'update.zip');
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Error al descargar: ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      int downloadedBytes = 0;

      final file = File(zipPath);
      final sink = file.openWrite();

      await for (var chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          onProgress(progress);
        }
      }

      await sink.close();
      onStatus('Descarga completada. Extrayendo archivos...');

      // Extraer el ZIP
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final extractDir = path.join(tempDir.path, 'extracted');
      await Directory(extractDir).create(recursive: true);

      for (final file in archive) {
        final filename = path.join(extractDir, file.name);
        if (file.isFile) {
          final data = file.content as List<int>;
          await File(filename).create(recursive: true);
          await File(filename).writeAsBytes(data);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }

      onStatus('Instalando actualización...');

      // Crear script de actualización que se ejecutará después de cerrar la app
      await _createUpdateScript(exeDir, extractDir);

      onStatus('Actualización lista. Reiniciando...');
    } catch (e) {
      throw Exception('Error al instalar actualización: $e');
    }
  }

  /// Crea un script PowerShell que reemplazará los archivos después de cerrar la app
  Future<void> _createUpdateScript(String targetDir, String sourceDir) async {
    final scriptPath = path.join(targetDir, 'update_installer.ps1');

    final script = '''
# Script de actualización automática
Start-Sleep -Seconds 2

# Copiar nuevos archivos
Copy-Item -Path "$sourceDir\\*" -Destination "$targetDir" -Recurse -Force

# Limpiar archivos temporales
Remove-Item -Path "${path.dirname(sourceDir)}" -Recurse -Force

# Eliminar este script
Remove-Item -Path "$scriptPath" -Force

# Reiniciar la aplicación
Start-Process -FilePath "$targetDir\\${path.basename(Platform.resolvedExecutable)}"
''';

    await File(scriptPath).writeAsString(script);

    // Ejecutar el script y cerrar la app actual
    await Process.start(
      'powershell.exe',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath,
      ],
      mode: ProcessStartMode.detached,
    );

    // Dar tiempo para que el script se inicie
    await Future.delayed(const Duration(seconds: 1));

    // Cerrar la aplicación actual
    exit(0);
  }

  /// Obtiene la URL del repositorio en GitHub
  String getRepositoryUrl() {
    return 'https://github.com/$githubRepo';
  }

  /// Obtiene la URL de la página de releases
  String getReleasesUrl() {
    return 'https://github.com/$githubRepo/releases';
  }

  /// Obtiene la versión actual de la aplicación
  String getCurrentVersion() {
    return currentVersion;
  }
}
