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

class ScriptExecutorService {
  Process? _currentProcess;

  /// Obtiene el proceso en ejecución actual
  Process? get currentProcess => _currentProcess;

  /// Detiene el proceso en ejecución actual
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

  /// Ejecuta un script de compra de boleto
  Future<void> executeScript({
    required String scriptName,
    required String displayName,
    required Function(String) onOutput,
    Function? onComplete,
    Function(Object)? onError,
  }) async {
    try {
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
          throw Exception('No se pudo compilar el script. Verifica que el archivo .ts existe.');
        }
      }

      onOutput('═══════════════════════════════════════════════════');
      onOutput('Ejecutando: $displayName');
      onOutput('═══════════════════════════════════════════════════');
      onOutput('');

      // Ejecutar el script con Node.js usando Process.start
      _currentProcess = await Process.start(
        nodePath,
        [scriptPath],
        workingDirectory: path.dirname(scriptPath),
        environment: {
          'PATH': '${path.dirname(nodePath)};${Platform.environment['PATH']!}',
        },
      );

      // Control de actividad del proceso
      DateTime lastActivity = DateTime.now();
      bool hasOutput = false;

      // Capturar la salida en tiempo real con decodificación UTF-8
      _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput(line);
        lastActivity = DateTime.now();
        hasOutput = true;
      });

      _currentProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onOutput('ERROR: $line');
        lastActivity = DateTime.now();
        hasOutput = true;
      });

      // Monitor de inactividad en paralelo
      final inactivityMonitor = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_currentProcess != null) {
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
            onOutput('ℹ️ Posibles causas:');
            onOutput('   • El navegador fue cerrado manualmente');
            onOutput('   • Playwright perdió conexión con el navegador');
            onOutput('   • El script está esperando interacción del usuario');
            onOutput('   • Hay un diálogo o popup bloqueando la ejecución');
            onOutput('');
            onOutput('💡 Recomendación: Usa el botón "Detener" para terminar la ejecución');
            
            // No matar automáticamente, dejar que el usuario decida
          }
        } else {
          timer.cancel();
        }
      });

      // Esperar a que termine con timeout de 30 minutos
      final exitCodeFuture = _currentProcess!.exitCode;
      final timeoutDuration = const Duration(minutes: 30);
      
      int? exitCode;
      try {
        exitCode = await exitCodeFuture.timeout(
          timeoutDuration,
          onTimeout: () {
            inactivityMonitor.cancel();
            onOutput('');
            onOutput('⏱️ ═══════════════════════════════════════════════════');
            onOutput('⏱️ TIMEOUT: La ejecución excedió ${timeoutDuration.inMinutes} minutos');
            onOutput('⏱️ ═══════════════════════════════════════════════════');
            onOutput('');
            onOutput('ℹ️ Posibles causas:');
            onOutput('   • El script tiene un problema de lógica infinita');
            onOutput('   • Hay un error que no permite que termine');
            onOutput('   • El navegador está en un estado inconsistente');
            onOutput('');
            
            // Matar el proceso si aún existe
            if (_currentProcess != null) {
              _currentProcess!.kill(ProcessSignal.sigkill);
            }
            
            throw TimeoutException('Script excedió el tiempo máximo de ejecución');
          },
        );
      } on TimeoutException {
        // Ya se manejó en onTimeout
        inactivityMonitor.cancel();
        _currentProcess = null;
        if (onError != null) {
          onError(TimeoutException('Timeout de ejecución'));
        }
        return;
      } catch (e) {
        inactivityMonitor.cancel();
        rethrow;
      }
      
      inactivityMonitor.cancel();
      _currentProcess = null; // Limpiar referencia

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
        // Validar scripts TypeScript
        final tsFiles = ['boletoSencillo.ts', 'boletoRedondo.ts', 'boletoAbierto.ts'];
        for (final tsFile in tsFiles) {
          final file = File(path.join(scriptCompraPath, tsFile));
          if (!await file.exists()) {
            warnings.add('Script $tsFile no encontrado');
          }
        }

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
