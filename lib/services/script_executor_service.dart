import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

class AvailableScript {
  final String name;
  final String fileName;
  final String displayName;

  AvailableScript({
    required this.name,
    required this.fileName,
    required this.displayName,
  });
}

/// Información de un proceso en ejecución
class ExecutionProcess {
  final String executionId;
  final Process process;
  final DateTime startTime;
  Timer? inactivityMonitor;
  
  ExecutionProcess({
    required this.executionId,
    required this.process,
    required this.startTime,
    this.inactivityMonitor,
  });
  
  void dispose() {
    inactivityMonitor?.cancel();
  }
}

class ScriptExecutorService {
  // Cambiar de un solo proceso a múltiples procesos
  final Map<String, ExecutionProcess> _activeProcesses = {};
  
  // Mantener compatibilidad con código legacy
  Process? _currentProcess;

  /// Obtiene el proceso en ejecución actual (legacy)
  Process? get currentProcess => _currentProcess;
  
  /// Obtiene todos los procesos activos
  Map<String, ExecutionProcess> get activeProcesses => _activeProcesses;
  
  /// Verifica si hay una ejecución activa para un executionId específico
  bool isExecutionActive(String executionId) {
    return _activeProcesses.containsKey(executionId);
  }
  
  /// Obtiene el número de ejecuciones activas
  int get activeExecutionsCount => _activeProcesses.length;

  /// Detiene el proceso en ejecución actual (legacy)
  Future<bool> stopCurrentExecution() async {
    if (_currentProcess != null) {
      try {
        _currentProcess!.kill(ProcessSignal.sigterm);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Si no se detuvo con SIGTERM, usar SIGKILL
        if (_currentProcess != null) {
          _currentProcess!.kill(ProcessSignal.sigkill);
        }
        
        _currentProcess = null;
        return true;
      } catch (e) {
        print('Error deteniendo proceso: $e');
        return false;
      }
    }
    return false;
  }

  /// Detiene una ejecución específica
  Future<bool> stopExecution(String executionId) async {
    final execProcess = _activeProcesses[executionId];
    if (execProcess != null) {
      try {
        // Cancelar monitor de inactividad
        execProcess.dispose();
        
        // Intentar terminar gracefully
        execProcess.process.kill(ProcessSignal.sigterm);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Si aún existe, forzar terminación
        try {
          execProcess.process.kill(ProcessSignal.sigkill);
        } catch (_) {
          // Ya terminó
        }
        
        _activeProcesses.remove(executionId);
        return true;
      } catch (e) {
        print('Error deteniendo ejecución $executionId: $e');
        _activeProcesses.remove(executionId);
        return false;
      }
    }
    return false;
  }

  /// Detiene todas las ejecuciones activas
  Future<int> stopAllExecutions() async {
    int stopped = 0;
    final ids = _activeProcesses.keys.toList();
    
    for (final id in ids) {
      if (await stopExecution(id)) {
        stopped++;
      }
    }
    
    return stopped;
  }

  /// Obtiene la ruta del workspace
  Future<String> getWorkspacePath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    return path.join(exeDir, 'workspace');
  }

  /// Obtiene lista de scripts TypeScript disponibles dinámicamente
  Future<List<AvailableScript>> getAvailableScripts() async {
    try {
      final workspacePath = await getWorkspacePath();
      final scriptCompraPath = path.join(workspacePath, 'ScriptCompra');
      final scriptCompraDir = Directory(scriptCompraPath);

      if (!await scriptCompraDir.exists()) {
        return [];
      }

      final scripts = <AvailableScript>[];
      
      // Buscar todos los archivos .ts que empiecen con "boleto"
      await for (final entity in scriptCompraDir.list()) {
        if (entity is File && entity.path.endsWith('.ts')) {
          final fileName = path.basename(entity.path);
          
          // Solo incluir archivos que empiecen con "boleto"
          if (fileName.toLowerCase().startsWith('boleto')) {
            // Convertir boletoSencillo.ts -> Boleto Sencillo
            final nameWithoutExtension = fileName.replaceAll('.ts', '');
            final displayName = _formatScriptName(nameWithoutExtension);
            
            scripts.add(AvailableScript(
              name: nameWithoutExtension,
              fileName: fileName,
              displayName: displayName,
            ));
          }
        }
      }

      // Ordenar alfabéticamente
      scripts.sort((a, b) => a.displayName.compareTo(b.displayName));
      
      return scripts;
    } catch (e) {
      print('Error obteniendo scripts disponibles: $e');
      return [];
    }
  }

  /// Formatea el nombre del script para mostrar (boletoSencillo -> Boleto Sencillo)
  String _formatScriptName(String scriptName) {
    // Remover "boleto" del inicio
    String name = scriptName;
    if (name.toLowerCase().startsWith('boleto')) {
      name = name.substring(6); // Quitar "boleto"
    }
    
    // Convertir camelCase a Title Case con espacios
    final result = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      if (i == 0) {
        result.write(name[i].toUpperCase());
      } else if (name[i].toUpperCase() == name[i] && name[i] != name[i].toLowerCase()) {
        result.write(' ${name[i]}');
      } else {
        result.write(name[i]);
      }
    }
    
    return 'Boleto $result';
  }

  /// Obtiene la ruta de Node.js portable
  Future<String> getNodePath() async {
    final workspacePath = await getWorkspacePath();
    return path.join(workspacePath, 'Node', 'node.exe');
  }

  /// Obtiene la ruta del script .js según el nombre
  Future<String> getScriptPath(String scriptName) async {
    final workspacePath = await getWorkspacePath();
    final scriptCompraPath = path.join(workspacePath, 'ScriptCompra');
    return path.join(scriptCompraPath, '$scriptName.js');
  }

  /// Compila los archivos TypeScript a JavaScript
  Future<void> compileTypeScript({
    required Function(String) onOutput,
  }) async {
    try {
      final workspacePath = await getWorkspacePath();
      final scriptCompraPath = path.join(workspacePath, 'ScriptCompra');
      final nodePath = await getNodePath();
      final npxPath = path.join(path.dirname(nodePath), 'npx.cmd');

      onOutput('Compilando archivos TypeScript...');
      onOutput('');

      final shell = Shell(
        workingDirectory: scriptCompraPath,
        verbose: false,
        environment: {
          'PATH': path.dirname(nodePath) + ';' + Platform.environment['PATH']!,
        },
      );

      // Ejecutar npx tsc
      final result = await shell.run('"$npxPath" tsc');

      for (var process in result) {
        if (process.stdout.toString().isNotEmpty) {
          onOutput(process.stdout.toString());
        }
        if (process.stderr.toString().isNotEmpty) {
          onOutput('ERROR: ${process.stderr}');
        }
      }

      onOutput('');
      onOutput('✓ Compilación completada');
    } catch (e) {
      onOutput('❌ Error en compilación: $e');
      rethrow;
    }
  }

  /// Ejecuta un script de compra de boleto (legacy - para compatibilidad)
  Future<void> executeScript({
    required String scriptName,
    required String displayName,
    required Function(String) onOutput,
    Function? onComplete,
    Function(Object)? onError,
  }) async {
    // Delegar a la nueva implementación con un ID temporal
    return executeScriptWithId(
      executionId: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
      scriptName: scriptName,
      displayName: displayName,
      onOutput: onOutput,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Ejecuta un script con ID de ejecución específico (nueva implementación)
  Future<void> executeScriptWithId({
    required String executionId,
    required String scriptName,
    required String displayName,
    required Function(String) onOutput,
    String? evidencePath,
    String? configPath,
    Function? onComplete,
    Function(Object)? onError,
    Function(String)? onScreenshotDetected,
  }) async {
    try {
      // Validar que no haya ya una ejecución con este ID
      if (_activeProcesses.containsKey(executionId)) {
        throw Exception('Ya existe una ejecución activa con ID: $executionId');
      }

      // Validación completa del workspace
      onOutput('🔍 Validando entorno de ejecución...');
      final validation = await validateWorkspace();
      
      if (!(validation['isReady'] as bool)) {
        final errors = validation['errors'] as List<String>;
        onOutput('❌ Validación fallida:');
        for (final error in errors) {
          onOutput('   • $error');
        }
        throw Exception('Workspace no está listo para ejecutar scripts');
      }

      final warnings = validation['warnings'] as List<String>;
      if (warnings.isNotEmpty) {
        onOutput('⚠️ Advertencias:');
        for (final warning in warnings) {
          onOutput('   • $warning');
        }
      }

      onOutput('✓ Validación completada');
      onOutput('');

      final nodePath = await getNodePath();
      final scriptPath = await getScriptPath(scriptName);

      // Verificar que el script existe
      if (!await File(scriptPath).exists()) {
        // Intentar compilar primero
        onOutput('⚠️ Script .js no encontrado, compilando TypeScript...');
        onOutput('');
        await compileTypeScript(onOutput: onOutput);
        onOutput('');
        
        // Verificar de nuevo
        if (!await File(scriptPath).exists()) {
          throw Exception('No se pudo compilar el script. Verifica que el archivo .ts exists.');
        }
      }

      // Crear carpeta de evidencias si se especificó
      if (evidencePath != null) {
        final evidenceDir = Directory(evidencePath);
        if (!await evidenceDir.exists()) {
          await evidenceDir.create(recursive: true);
          onOutput('📁 Carpeta de evidencias creada: $evidencePath');
        }
      }

      onOutput('═══════════════════════════════════════════════════');
      onOutput('Ejecutando: $displayName');
      onOutput('ID de ejecución: $executionId');
      if (evidencePath != null) {
        onOutput('Evidencias: $evidencePath');
      }
      onOutput('═══════════════════════════════════════════════════');
      onOutput('');

      // Preparar variables de entorno (heredar del sistema + agregar las nuestras)
      final environment = <String, String>{
        ...Platform.environment, // Heredar todas las variables del sistema
      };
      
      // Si hay path de evidencias, pasarlo como variable de entorno
      if (evidencePath != null) {
        environment['EVIDENCE_PATH'] = evidencePath;
        onOutput('');
        onOutput('� ═══════════════════════════════════════════════════');
        onOutput('🔍 DEBUG - Variables de entorno configuradas:');
        onOutput('🔍 ═══════════════════════════════════════════════════');
        onOutput('🔍 EVIDENCE_PATH = "$evidencePath"');
      } else {
        onOutput('');
        onOutput('⚠️ ADVERTENCIA: evidencePath es NULL - no se configuró EVIDENCE_PATH');
      }
      
      // Si hay config personalizado, pasarlo
      if (configPath != null) {
        environment['CONFIG_PATH'] = configPath;
        onOutput('🔍 CONFIG_PATH = "$configPath"');
      } else {
        onOutput('⚠️ ADVERTENCIA: configPath es NULL - no se configuró CONFIG_PATH');
      }
      
      onOutput('🔍 ═══════════════════════════════════════════════════');
      onOutput('');

      // Ejecutar el script con Node.js usando Process.start
      final process = await Process.start(
        nodePath,
        [scriptPath],
        workingDirectory: path.dirname(scriptPath),
        environment: environment,
      );

      // Mantener compatibilidad con legacy
      _currentProcess = process;

      // Control de actividad del proceso
      DateTime lastActivity = DateTime.now();
      bool hasOutput = false;
      
      // Watcher de screenshots si se proporcionó evidencePath
      StreamSubscription? screenshotWatcher;
      if (evidencePath != null && onScreenshotDetected != null) {
        final evidenceDir = Directory(evidencePath);
        screenshotWatcher = evidenceDir.watch(events: FileSystemEvent.create).listen((event) {
          if (event is FileSystemCreateEvent) {
            final fileName = path.basename(event.path);
            if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
              onScreenshotDetected(event.path);
            }
          }
        });
      }

      // Capturar la salida en tiempo real con decodificación UTF-8
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput(line);
        lastActivity = DateTime.now();
        hasOutput = true;
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput('ERROR: $line');
        lastActivity = DateTime.now();
        hasOutput = true;
      });

      // Monitor de inactividad en paralelo
      final inactivityMonitor = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_activeProcesses.containsKey(executionId)) {
          final inactiveDuration = DateTime.now().difference(lastActivity);
          
          // Si ha estado inactivo por más de 5 minutos después de haber tenido salida
          if (hasOutput && inactiveDuration.inMinutes >= 5) {
            timer.cancel();
            onOutput('');
            onOutput('⚠️ ═══════════════════════════════════════════════════');
            onOutput('⚠️ INACTIVIDAD DETECTADA');
            onOutput('⚠️ No hay salida desde hace ${inactiveDuration.inMinutes} minutos');
            onOutput('⚠️ ═══════════════════════════════════════════════════');
            onOutput('');
            onOutput('💡 Usa el botón "Detener" para terminar la ejecución');
          }
        } else {
          timer.cancel();
        }
      });
      
      // Registrar proceso activo
      final execProcess = ExecutionProcess(
        executionId: executionId,
        process: process,
        startTime: DateTime.now(),
        inactivityMonitor: inactivityMonitor,
      );
      _activeProcesses[executionId] = execProcess;

      // Esperar a que termine con timeout de 30 minutos
      final exitCodeFuture = process.exitCode;
      final timeoutDuration = const Duration(minutes: 30);
      
      int? exitCode;
      try {
        exitCode = await exitCodeFuture.timeout(
          timeoutDuration,
          onTimeout: () {
            execProcess.dispose();
            onOutput('');
            onOutput('⏱️ ═══════════════════════════════════════════════════');
            onOutput('⏱️ TIMEOUT: La ejecución excedió ${timeoutDuration.inMinutes} minutos');
            onOutput('⏱️ ═══════════════════════════════════════════════════');
            
            // Matar el proceso si aún existe
            try {
              process.kill(ProcessSignal.sigkill);
            } catch (_) {}
            
            throw TimeoutException('Script excedió el tiempo máximo de ejecución');
          },
        );
      } on TimeoutException {
        _activeProcesses.remove(executionId);
        screenshotWatcher?.cancel();
        if (_currentProcess == process) _currentProcess = null;
        if (onError != null) {
          onError(TimeoutException('Timeout de ejecución'));
        }
        return;
      } catch (e) {
        execProcess.dispose();
        _activeProcesses.remove(executionId);
        screenshotWatcher?.cancel();
        rethrow;
      }
      
      // Limpiar recursos
      execProcess.dispose();
      _activeProcesses.remove(executionId);
      screenshotWatcher?.cancel();
      if (_currentProcess == process) _currentProcess = null;

      onOutput('');
      onOutput('═══════════════════════════════════════════════════');
      if (exitCode == 0) {
        onOutput('✓ Ejecución completada exitosamente');
      } else {
        onOutput('❌ Ejecución terminó con errores (código: $exitCode)');
      }
      onOutput('═══════════════════════════════════════════════════');

      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      // Limpiar en caso de error
      _activeProcesses.remove(executionId);
      
      onOutput('');
      onOutput('❌ Error fatal: $e');
      if (onError != null) {
        onError(e);
      }
      rethrow;
    }
  }

  /// Verifica si el workspace está configurado correctamente
  Future<Map<String, dynamic>> validateWorkspace() async {
    final validation = {
      'isReady': false,
      'errors': <String>[],
      'warnings': <String>[],
    };

    try {
      final workspacePath = await getWorkspacePath();
      final nodePath = await getNodePath();
      final scriptCompraPath = path.join(workspacePath, 'ScriptCompra');
      final configPath = path.join(workspacePath, 'config.json');

      final errors = validation['errors'] as List<String>;
      final warnings = validation['warnings'] as List<String>;

      // Validar directorio workspace
      final workspaceDir = Directory(workspacePath);
      if (!await workspaceDir.exists()) {
        errors.add('Workspace no existe. Clona el repositorio primero.');
        return validation;
      }

      // Validar Node.js
      final nodeFile = File(nodePath);
      if (!await nodeFile.exists()) {
        errors.add('Node.js no encontrado en: $nodePath');
      }

      // Validar carpeta ScriptCompra
      final scriptCompraDir = Directory(scriptCompraPath);
      if (!await scriptCompraDir.exists()) {
        errors.add('Carpeta ScriptCompra no encontrada');
      } else {
        // No validar scripts específicos - el usuario puede tener cualquier nombre
        // Solo validar que exista la carpeta

        // Validar package.json
        final packageJson = File(path.join(scriptCompraPath, 'package.json'));
        if (!await packageJson.exists()) {
          warnings.add('package.json no encontrado en ScriptCompra');
        }
      }

      // Validar config.json
      final configFile = File(configPath);
      if (!await configFile.exists()) {
        warnings.add('config.json no encontrado (se creará automáticamente)');
      }

      validation['isReady'] = errors.isEmpty;
      return validation;
    } catch (e) {
      final errors = validation['errors'] as List<String>;
      errors.add('Error al validar workspace: $e');
      return validation;
    }
  }

  /// Verifica si el workspace está configurado correctamente (legacy)
  Future<bool> isWorkspaceReady() async {
    final validation = await validateWorkspace();
    return validation['isReady'] as bool;
  }
}
