import 'package:flutter/foundation.dart';
import '../models/config_model.dart';
import '../models/update_info_model.dart';
import '../services/config_service.dart';
import '../services/git_service.dart';
import '../services/script_executor_service.dart';
import '../services/update_service.dart';
import '../constants/app_constants.dart';

class AppStateProvider with ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final GitService _gitService = GitService();
  final ScriptExecutorService _scriptService = ScriptExecutorService();
  final UpdateService _updateService = UpdateService();

  ConfigModel? _config;
  bool _isLoading = false;
  bool _isRepositoryCloned = false;
  bool _isExecuting = false;
  String _terminalOutput = '';
  List<String> _terminalLines = [];
  UpdateInfo? _availableUpdate;
  bool _isCheckingUpdates = false;

  // Getters
  ConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  bool get isRepositoryCloned => _isRepositoryCloned;
  bool get isExecuting => _isExecuting;
  String get terminalOutput => _terminalOutput;
  List<String> get terminalLines => _terminalLines;
  UpdateInfo? get availableUpdate => _availableUpdate;
  bool get isCheckingUpdates => _isCheckingUpdates;
  bool get hasAvailableUpdate => _availableUpdate != null;

  ConfigService get configService => _configService;
  GitService get gitService => _gitService;
  ScriptExecutorService get scriptService => _scriptService;
  UpdateService get updateService => _updateService;

  /// Inicializa el estado de la aplicación
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cargar configuración
      _config = await _configService.readConfig();

      // Verificar si el repositorio está clonado
      _isRepositoryCloned = await _gitService.isRepositoryCloned();

      _isLoading = false;
      notifyListeners();

      // Verificar actualizaciones en segundo plano (si está habilitado)
      if (AppConstants.checkUpdatesOnStartup) {
        checkForUpdates(silent: true);
      }
    } catch (e) {
      print('Error inicializando app: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> checkForUpdates({bool silent = false}) async {
    if (_isCheckingUpdates) return;

    _isCheckingUpdates = true;
    if (!silent) notifyListeners();

    try {
      final updateInfo = await _updateService.checkForUpdates();
      _availableUpdate = updateInfo;
      _isCheckingUpdates = false;
      notifyListeners();
    } catch (e) {
      print('Error verificando actualizaciones: $e');
      _isCheckingUpdates = false;
      if (!silent) notifyListeners();
    }
  }

  /// Limpia la notificación de actualización disponible
  void clearUpdateNotification() {
    _availableUpdate = null;
    notifyListeners();
  }

  /// Actualiza la configuración
  Future<void> updateConfig(ConfigModel newConfig) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _configService.writeConfig(newConfig);
      _config = newConfig;
    } catch (e) {
      print('Error actualizando configuración: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga la configuración desde el archivo
  Future<void> reloadConfig() async {
    try {
      _config = await _configService.readConfig();
      notifyListeners();
    } catch (e) {
      print('Error recargando configuración: $e');
    }
  }

  /// Agrega una línea al terminal
  void addTerminalOutput(String line) {
    _terminalOutput += line;
    if (!line.endsWith('\n')) {
      _terminalOutput += '\n';
    }
    _terminalLines.add(line);

    // Limitar el número de líneas para evitar problemas de memoria
    if (_terminalLines.length > AppConstants.maxTerminalLines) {
      final removeCount = _terminalLines.length - AppConstants.maxTerminalLines;
      _terminalLines.removeRange(0, removeCount);
      
      // Reconstruir el output desde las líneas restantes
      _terminalOutput = _terminalLines.join('\n') + '\n';
    }

    // Limitar el tamaño total del output
    if (_terminalOutput.length > AppConstants.maxLogSize) {
      final excess = _terminalOutput.length - AppConstants.maxLogSize;
      _terminalOutput = '...[truncado $excess caracteres]...\n' + 
                       _terminalOutput.substring(excess);
    }

    notifyListeners();
  }

  /// Limpia el terminal
  void clearTerminal() {
    _terminalOutput = '';
    _terminalLines.clear();
    notifyListeners();
  }

  /// Actualiza el estado de ejecución
  void setExecuting(bool value) {
    _isExecuting = value;
    notifyListeners();
  }

  /// Actualiza el estado del repositorio
  void setRepositoryCloned(bool value) {
    _isRepositoryCloned = value;
    notifyListeners();
  }

  /// Actualiza el estado de carga
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
