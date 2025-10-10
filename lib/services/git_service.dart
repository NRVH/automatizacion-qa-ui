import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GitService {
  final String repoUrl = 'http://gitlab.estrellaroja.com.mx/java/estrella-roja-qa-automatizacion.git';
  final String defaultBranch = 'feature/mejoras-script-compra';
  
  final _storage = const FlutterSecureStorage();
  static const String _usernameKey = 'git_username';
  static const String _passwordKey = 'git_password';
  static const String _branchKey = 'git_branch';

  /// Guarda las credenciales de Git de forma segura
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Obtiene las credenciales guardadas
  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    return {'username': username, 'password': password};
  }

  /// Verifica si hay credenciales guardadas
  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds['username'] != null && creds['password'] != null;
  }

  /// Guarda la rama seleccionada
  Future<void> saveBranch(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_branchKey, branch);
  }

  /// Obtiene la rama guardada o devuelve la rama por defecto
  Future<String> getBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_branchKey) ?? defaultBranch;
  }

  /// Obtiene la ruta del workspace
  Future<String> getWorkspacePath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    return path.join(exeDir, 'workspace');
  }

  /// Construye la URL con credenciales
  Future<String> _getAuthenticatedUrl() async {
    final creds = await getCredentials();
    final username = creds['username'];
    final password = creds['password'];

    if (username == null || password == null) {
      throw Exception('Credenciales de Git no configuradas');
    }

    // Construir URL con credenciales: http://username:password@gitlab.com/...
    final uri = Uri.parse(repoUrl);
    final authenticatedUrl = 'http://$username:$password@${uri.host}${uri.path}';
    
    return authenticatedUrl;
  }

  /// Verifica si Git está instalado en el sistema
  Future<bool> isGitInstalled() async {
    try {
      final result = await Process.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si hay conexión VPN activa (Windows)
  Future<bool> isVpnConnected() async {
    try {
      // Ejecutar comando para obtener adaptadores de red
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          r'Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and ($_.InterfaceDescription -like "*VPN*" -or $_.InterfaceDescription -like "*Virtual*" -or $_.Name -like "*VPN*")} | Select-Object -First 1'
        ],
      );
      
      // Si hay output, hay una VPN conectada
      return result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      // Si falla, asumir que no hay VPN (no bloquear)
      return false;
    }
  }

  /// Verifica conectividad con el servidor GitLab
  Future<bool> canReachGitLabServer() async {
    try {
      final uri = Uri.parse(repoUrl);
      final result = await Process.run(
        'ping',
        ['-n', '1', uri.host],
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Clona el repositorio
  Future<String> cloneRepository({
    required Function(String) onOutput,
    String? branch,
  }) async {
    try {
      // Validar Git instalado
      if (!await isGitInstalled()) {
        throw Exception('Git no está instalado en el sistema');
      }

      // Verificar conexión VPN
      onOutput('🔍 Verificando conexión VPN...');
      final hasVpn = await isVpnConnected();
      if (!hasVpn) {
        onOutput('⚠️ Advertencia: No se detectó conexión VPN activa');
        onOutput('💡 Si usas VPN corporativa, conéctala primero');
      } else {
        onOutput('✓ VPN detectada');
      }

      // Verificar conectividad con GitLab
      onOutput('🔍 Verificando conexión a GitLab...');
      final canReach = await canReachGitLabServer();
      if (!canReach) {
        throw Exception(
          'No se puede alcanzar el servidor GitLab.\n'
          '• Verifica tu conexión a internet\n'
          '• Si usas VPN, asegúrate de estar conectado\n'
          '• Verifica que puedas acceder a: $repoUrl'
        );
      }
      onOutput('✓ Servidor GitLab alcanzable');

      final workspacePath = await getWorkspacePath();
      final workspaceDir = Directory(workspacePath);

      // Si ya existe, respaldar antes de eliminar
      if (await workspaceDir.exists()) {
        onOutput('⚠️ Workspace existente detectado, eliminando...');
        try {
          await workspaceDir.delete(recursive: true);
        } catch (e) {
          throw Exception('No se pudo eliminar workspace existente. Cierra cualquier programa que esté usando los archivos.');
        }
      }

      onOutput('Preparando clonación del repositorio...');
      
      final authenticatedUrl = await _getAuthenticatedUrl();
      final selectedBranch = branch ?? await getBranch();

      onOutput('Clonando desde: $repoUrl');
      onOutput('Rama: $selectedBranch');

      final shell = Shell(
        workingDirectory: path.dirname(workspacePath),
        verbose: false,
        throwOnError: false,
      );

      // Clonar con la rama específica y timeout
      final result = await shell.run('''
        git clone --branch $selectedBranch --depth 1 $authenticatedUrl workspace
      ''').timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
        },
      );

      // Verificar que el clone fue exitoso
      if (!await workspaceDir.exists()) {
        throw Exception('La clonación falló. Verifica credenciales y conexión.');
      }

      // Validar estructura del repositorio
      final nodeDir = Directory(path.join(workspacePath, 'Node'));
      final scriptDir = Directory(path.join(workspacePath, 'ScriptCompra'));
      
      if (!await nodeDir.exists()) {
        throw Exception('Estructura del repositorio inválida: falta carpeta Node/');
      }
      if (!await scriptDir.exists()) {
        throw Exception('Estructura del repositorio inválida: falta carpeta ScriptCompra/');
      }

      onOutput('✓ Repositorio clonado exitosamente');
      onOutput('✓ Estructura validada correctamente');
      
      // Limpiar archivos .js y compilar TypeScript automáticamente
      onOutput('');
      onOutput('🔧 Compilando scripts TypeScript...');
      await _compileTypeScriptAfterClone(workspacePath, onOutput);
      
      return workspacePath;
    } catch (e) {
      onOutput('❌ Error al clonar: $e');
      rethrow;
    }
  }

  /// Actualiza el repositorio (git pull)
  Future<void> pullRepository({
    required Function(String) onOutput,
  }) async {
    try {
      final workspacePath = await getWorkspacePath();
      final workspaceDir = Directory(workspacePath);

      if (!await workspaceDir.exists()) {
        throw Exception('El repositorio no ha sido clonado aún');
      }

      onOutput('Verificando estado del repositorio...');

      final shell = Shell(
        workingDirectory: workspacePath,
        verbose: false,
        throwOnError: false,
      );

      // Verificar si hay cambios locales
      final statusResult = await shell.run('git status --porcelain');
      final hasChanges = statusResult.first.stdout.toString().trim().isNotEmpty;
      
      if (hasChanges) {
        onOutput('⚠️ Hay cambios locales, guardando en stash...');
        await shell.run('git stash');
      }

      onOutput('Actualizando repositorio...');

      await shell.run('git pull').timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al actualizar');
        },
      );
      
      // Restaurar cambios si se hizo stash
      if (hasChanges) {
        onOutput('Restaurando cambios locales...');
        await shell.run('git stash pop');
      }

      onOutput('✓ Repositorio actualizado exitosamente');
      
      // Limpiar archivos .js y compilar TypeScript automáticamente
      onOutput('');
      onOutput('🔧 Compilando scripts TypeScript...');
      await _compileTypeScriptAfterClone(workspacePath, onOutput);
    } catch (e) {
      onOutput('❌ Error al actualizar: $e');
      onOutput('💡 Si persiste, intenta clonar de nuevo el repositorio');
      rethrow;
    }
  }

  /// Limpia archivos .js y compila TypeScript después de clone/pull
  Future<void> _compileTypeScriptAfterClone(
    String workspacePath,
    Function(String) onOutput,
  ) async {
    try {
      final scriptCompraPath = path.join(workspacePath, 'ScriptCompra');
      final scriptCompraDir = Directory(scriptCompraPath);

      if (!await scriptCompraDir.exists()) {
        onOutput('⚠️ Carpeta ScriptCompra no encontrada, saltando compilación');
        return;
      }

      // Eliminar todos los archivos .js
      int deletedCount = 0;
      await for (final entity in scriptCompraDir.list()) {
        if (entity is File && entity.path.endsWith('.js')) {
          await entity.delete();
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) {
        onOutput('🗑️ Eliminados $deletedCount archivos .js antiguos');
      }

      // Compilar TypeScript
      final nodePath = path.join(workspacePath, 'Node', 'node.exe');
      final npxPath = path.join(workspacePath, 'Node', 'npx.cmd');

      if (!await File(nodePath).exists() || !await File(npxPath).exists()) {
        onOutput('⚠️ Node.js no encontrado, saltando compilación');
        return;
      }

      final shell = Shell(
        workingDirectory: scriptCompraPath,
        verbose: false,
        throwOnError: false,
        environment: {
          'PATH': '${path.dirname(nodePath)};${Platform.environment['PATH']!}',
        },
      );

      // Ejecutar npx tsc
      await shell.run('"$npxPath" tsc');
      
      onOutput('✓ TypeScript compilado exitosamente');
    } catch (e) {
      onOutput('⚠️ Error en compilación automática: $e');
      onOutput('💡 Puedes compilar manualmente más tarde');
      // No lanzar excepción, solo advertir
    }
  }

  /// Verifica si el repositorio ya está clonado
  Future<bool> isRepositoryCloned() async {
    final workspacePath = await getWorkspacePath();
    final gitDir = Directory(path.join(workspacePath, '.git'));
    return await gitDir.exists();
  }

  /// Obtiene la rama actual del repositorio
  Future<String?> getCurrentBranch() async {
    try {
      final workspacePath = await getWorkspacePath();
      final shell = Shell(
        workingDirectory: workspacePath,
        verbose: false,
      );

      final result = await shell.run('git branch --show-current');
      if (result.isNotEmpty && result.first.stdout != null) {
        return result.first.stdout.toString().trim();
      }
    } catch (e) {
      print('Error obteniendo rama actual: $e');
    }
    return null;
  }

  /// Cambia de rama
  Future<void> checkoutBranch({
    required String branch,
    required Function(String) onOutput,
  }) async {
    try {
      final workspacePath = await getWorkspacePath();
      final shell = Shell(
        workingDirectory: workspacePath,
        verbose: false,
      );

      onOutput('Cambiando a rama: $branch');

      await shell.run('git fetch origin');
      await shell.run('git checkout $branch');
      await shell.run('git pull origin $branch');

      await saveBranch(branch);

      onOutput('✓ Cambio de rama exitoso');
    } catch (e) {
      onOutput('❌ Error al cambiar de rama: $e');
      rethrow;
    }
  }
}
