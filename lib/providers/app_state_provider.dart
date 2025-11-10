import 'package:flutter/foundation.dart';
import '../models/config_model.dart';
import '../models/update_info_model.dart';
import '../models/execution_instance.dart';
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
  String? _selectedScriptName; // Persistir script seleccionado
  
  // Gestión de ejecuciones múltiples
  final Map<String, ExecutionInstance> _executions = {};
  String? _activeExecutionId;
  static const int maxExecutions = 10;

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
  String? get selectedScriptName => _selectedScriptName;
  
  // Getters de ejecuciones
  Map<String, ExecutionInstance> get executions => _executions;
  String? get activeExecutionId => _activeExecutionId;
  ExecutionInstance? get activeExecution => 
      _activeExecutionId != null ? _executions[_activeExecutionId] : null;
  int get executionsCount => _executions.length;
  bool get canCreateNewExecution => _executions.length < maxExecutions;
  List<ExecutionInstance> get executionsList => _executions.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

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

  /// Guarda el script seleccionado
  void setSelectedScript(String? scriptName) {
    _selectedScriptName = scriptName;
    notifyListeners();
  }

  // ========== GESTIÓN DE EJECUCIONES MÚLTIPLES ==========

  /// Crea una nueva ejecución
  Future<String?> createNewExecution({
    required String scriptName,
    ConfigModel? config,
  }) async {
    // Validar límite máximo
    if (_executions.length >= maxExecutions) {
      return null; // No se puede crear más
    }

    try {
      final workspacePath = await _gitService.getWorkspacePath();
      final executionId = ExecutionInstance.generateId();
      final timestamp = DateTime.now();
      
      final instance = ExecutionInstance(
        id: executionId,
        scriptName: scriptName,
        createdAt: timestamp,
        config: config ?? _config ?? ConfigModel.empty(),
        evidencePath: ExecutionInstance.generateEvidencePath(
          workspacePath: workspacePath,
          scriptName: scriptName,
          timestamp: timestamp,
          executionId: executionId,
        ),
        status: ExecutionStatus.idle,
      );

      _executions[executionId] = instance;
      _activeExecutionId = executionId;
      notifyListeners();

      return executionId;
    } catch (e) {
      print('Error creando ejecución: $e');
      return null;
    }
  }

  /// Elimina una ejecución (solo si no está en ejecución)
  bool removeExecution(String executionId) {
    final execution = _executions[executionId];
    if (execution == null) return false;
    
    // No permitir eliminar si está en ejecución
    if (execution.status == ExecutionStatus.running) {
      return false;
    }

    // Limpiar archivo de configuración temporal
    configService.deleteTemporaryConfig(executionId);

    _executions.remove(executionId);
    
    // Si era la ejecución activa, seleccionar otra
    if (_activeExecutionId == executionId) {
      _activeExecutionId = _executions.keys.isNotEmpty 
          ? _executions.keys.first 
          : null;
    }
    
    notifyListeners();
    return true;
  }

  /// Establece la ejecución activa
  void setActiveExecution(String executionId) {
    if (_executions.containsKey(executionId)) {
      _activeExecutionId = executionId;
      notifyListeners();
    }
  }

  /// Obtiene una ejecución por ID
  ExecutionInstance? getExecution(String executionId) {
    return _executions[executionId];
  }

  /// Actualiza el estado de una ejecución
  void updateExecution(String executionId, ExecutionInstance updatedExecution) {
    if (_executions.containsKey(executionId)) {
      _executions[executionId] = updatedExecution;
      notifyListeners();
    }
  }

  /// Agrega un log a una ejecución específica
  void addExecutionLog(String executionId, String message) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.addLog(message);
      notifyListeners();
    }
  }

  /// Incrementa el contador de screenshots de una ejecución
  void incrementExecutionScreenshots(String executionId) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.incrementScreenshots();
      notifyListeners();
    }
  }

  /// Marca una ejecución como iniciada
  void markExecutionAsStarted(String executionId) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.markAsStarted();
      notifyListeners();
    }
  }

  /// Marca una ejecución como completada
  void markExecutionAsCompleted(String executionId) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.markAsCompleted();
      notifyListeners();
    }
  }

  /// Marca una ejecución como fallida
  void markExecutionAsFailed(String executionId, String error) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.markAsFailed(error);
      notifyListeners();
    }
  }

  /// Marca una ejecución como cancelada
  void markExecutionAsCancelled(String executionId) {
    final execution = _executions[executionId];
    if (execution != null) {
      execution.markAsCancelled();
      notifyListeners();
    }
  }

  /// Limpia todas las ejecuciones completadas/fallidas/canceladas
  int clearCompletedExecutions() {
    final idsToRemove = _executions.entries
        .where((entry) => entry.value.status != ExecutionStatus.running)
        .map((entry) => entry.key)
        .toList();

    for (var id in idsToRemove) {
      _executions.remove(id);
    }

    // Actualizar ejecución activa si fue eliminada
    if (_activeExecutionId != null && !_executions.containsKey(_activeExecutionId)) {
      _activeExecutionId = _executions.keys.isNotEmpty 
          ? _executions.keys.first 
          : null;
    }

    if (idsToRemove.isNotEmpty) {
      notifyListeners();
    }

    return idsToRemove.length;
  }
}
