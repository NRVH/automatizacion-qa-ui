import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/config_model.dart';

class ConfigService {
  static const String _configFileName = 'config.json';

  /// Obtiene la ruta del workspace (donde están los scripts)
  Future<String> getWorkspacePath() async {
    // Obtener la ruta del ejecutable
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    
    // El workspace estará en la carpeta "workspace" junto al ejecutable
    final workspacePath = path.join(exeDir, 'workspace');
    
    // Si no existe, crearlo
    final workspaceDir = Directory(workspacePath);
    if (!await workspaceDir.exists()) {
      await workspaceDir.create(recursive: true);
    }
    
    return workspacePath;
  }

  /// Obtiene la ruta completa del archivo config.json
  Future<String> getConfigPath() async {
    final workspacePath = await getWorkspacePath();
    return path.join(workspacePath, _configFileName);
  }

  /// Lee el archivo config.json
  Future<ConfigModel> readConfig() async {
    try {
      final configPath = await getConfigPath();
      final file = File(configPath);

      if (!await file.exists()) {
        // Si no existe, crear uno con valores por defecto
        print('⚠️ config.json no encontrado, creando uno nuevo...');
        final defaultConfig = ConfigModel.defaultConfig();
        await writeConfig(defaultConfig);
        return defaultConfig;
      }

      final jsonString = await file.readAsString();
      
      // Validar que no esté vacío
      if (jsonString.trim().isEmpty) {
        print('⚠️ config.json vacío, usando valores por defecto');
        return ConfigModel.defaultConfig();
      }

      // Intentar parsear JSON
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      
      // Validar estructura básica
      if (!jsonMap.containsKey('browser') || !jsonMap.containsKey('search')) {
        print('⚠️ config.json con estructura inválida, recreando...');
        final defaultConfig = ConfigModel.defaultConfig();
        await writeConfig(defaultConfig);
        return defaultConfig;
      }

      return ConfigModel.fromJson(jsonMap);
    } catch (e) {
      print('❌ Error leyendo config.json: $e');
      print('💡 Respaldando archivo corrupto y creando uno nuevo...');
      
      // Respaldar archivo corrupto
      try {
        final configPath = await getConfigPath();
        final backupPath = '$configPath.backup_${DateTime.now().millisecondsSinceEpoch}';
        await File(configPath).copy(backupPath);
        print('✓ Backup creado: $backupPath');
      } catch (_) {}
      
      // Crear nuevo config por defecto
      final defaultConfig = ConfigModel.defaultConfig();
      await writeConfig(defaultConfig);
      return defaultConfig;
    }
  }

  /// Escribe el archivo config.json
  Future<void> writeConfig(ConfigModel config) async {
    try {
      final configPath = await getConfigPath();
      final file = File(configPath);

      final jsonMap = config.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error escribiendo config.json: $e');
      rethrow;
    }
  }

  /// Valida si el archivo config.json existe
  Future<bool> configExists() async {
    final configPath = await getConfigPath();
    final file = File(configPath);
    return await file.exists();
  }
}
