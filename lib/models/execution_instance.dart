import 'package:uuid/uuid.dart';
import 'config_model.dart';

/// Estados posibles de una ejecución
enum ExecutionStatus {
  idle,       // Creada pero no iniciada
  running,    // En ejecución
  completed,  // Finalizada exitosamente
  failed,     // Finalizada con errores
  cancelled,  // Cancelada por el usuario
}

/// Representa una instancia de ejecución de script
class ExecutionInstance {
  final String id;
  final String scriptName;
  final DateTime createdAt;
  final ConfigModel config;
  final String evidencePath;
  
  ExecutionStatus status;
  DateTime? startTime;
  DateTime? endTime;
  List<String> logs;
  int screenshotCount;
  String? errorMessage;

  ExecutionInstance({
    required this.id,
    required this.scriptName,
    required this.createdAt,
    required this.config,
    required this.evidencePath,
    this.status = ExecutionStatus.idle,
    this.startTime,
    this.endTime,
    List<String>? logs,
    this.screenshotCount = 0,
    this.errorMessage,
  }) : logs = logs ?? [];

  /// Genera un ID único para la ejecución
  static String generateId() {
    return const Uuid().v4().substring(0, 8); // Usar solo 8 caracteres
  }

  /// Genera el path de evidencias basado en script y timestamp
  static String generateEvidencePath({
    required String workspacePath,
    required String scriptName,
    required DateTime timestamp,
    required String executionId,
  }) {
    // Extraer nombre base del script (sin .js o .ts)
    final baseName = scriptName
        .replaceAll('.js', '')
        .replaceAll('.ts', '')
        .toLowerCase();
    
    // Formato: evidencias/sencillo_2025-11-10_17-30-45_abc123/
    final dateStr = timestamp.toString().substring(0, 10); // 2025-11-10
    final timeStr = timestamp.toString().substring(11, 19).replaceAll(':', '-'); // 17-30-45
    
    return '$workspacePath/evidencias/${baseName}_${dateStr}_${timeStr}_$executionId';
  }

  /// Nombre para mostrar en el tab
  String get displayName {
    final time = createdAt.toString().substring(11, 19); // HH:mm:ss
    return '$scriptName - $time';
  }

  /// Nombre corto para el tab (máximo 20 caracteres)
  String get shortDisplayName {
    final time = createdAt.toString().substring(11, 16); // HH:mm
    final shortScript = scriptName.length > 12 
        ? '${scriptName.substring(0, 12)}...' 
        : scriptName;
    return '$shortScript $time';
  }

  /// Icono según el estado
  String get statusIcon {
    switch (status) {
      case ExecutionStatus.idle:
        return '⚪';
      case ExecutionStatus.running:
        return '🔵';
      case ExecutionStatus.completed:
        return '✅';
      case ExecutionStatus.failed:
        return '❌';
      case ExecutionStatus.cancelled:
        return '🚫';
    }
  }

  /// Color según el estado
  String get statusColor {
    switch (status) {
      case ExecutionStatus.idle:
        return 'grey';
      case ExecutionStatus.running:
        return 'blue';
      case ExecutionStatus.completed:
        return 'green';
      case ExecutionStatus.failed:
        return 'red';
      case ExecutionStatus.cancelled:
        return 'orange';
    }
  }

  /// Puede cerrarse el tab (solo si no está en ejecución)
  bool get canClose {
    return status != ExecutionStatus.running;
  }

  /// Duración de la ejecución
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Agregar log
  void addLog(String message) {
    logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
  }

  /// Incrementar contador de screenshots
  void incrementScreenshots() {
    screenshotCount++;
  }

  /// Marcar como iniciada
  void markAsStarted() {
    status = ExecutionStatus.running;
    startTime = DateTime.now();
  }

  /// Marcar como completada
  void markAsCompleted() {
    status = ExecutionStatus.completed;
    endTime = DateTime.now();
  }

  /// Marcar como fallida
  void markAsFailed(String error) {
    status = ExecutionStatus.failed;
    endTime = DateTime.now();
    errorMessage = error;
  }

  /// Marcar como cancelada
  void markAsCancelled() {
    status = ExecutionStatus.cancelled;
    endTime = DateTime.now();
  }

  /// Crear copia con modificaciones
  ExecutionInstance copyWith({
    String? id,
    String? scriptName,
    DateTime? createdAt,
    ConfigModel? config,
    String? evidencePath,
    ExecutionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? logs,
    int? screenshotCount,
    String? errorMessage,
  }) {
    return ExecutionInstance(
      id: id ?? this.id,
      scriptName: scriptName ?? this.scriptName,
      createdAt: createdAt ?? this.createdAt,
      config: config ?? this.config,
      evidencePath: evidencePath ?? this.evidencePath,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      logs: logs ?? this.logs,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convertir a JSON (para metadata.json)
  Map<String, dynamic> toJson() {
    return {
      'executionId': id,
      'scriptName': scriptName,
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'config': config.toJson(),
      'evidencePath': evidencePath,
      'screenshotCount': screenshotCount,
      'errorMessage': errorMessage,
      'duration': duration?.inSeconds,
    };
  }
}
