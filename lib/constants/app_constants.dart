/// Constantes globales de la aplicación
class AppConstants {
  // Git
  static const String gitRepoUrl = 'http://gitlab.estrellaroja.com.mx/java/estrella-roja-qa-automatizacion.git';
  static const String defaultBranch = 'feature/mejoras-script-compra';
  
  // Timeouts
  static const Duration gitCloneTimeout = Duration(minutes: 5);
  static const Duration gitPullTimeout = Duration(minutes: 2);
  static const Duration scriptExecutionTimeout = Duration(minutes: 30); // Timeout para scripts largos
  static const Duration scriptIdleTimeout = Duration(minutes: 5); // Timeout si no hay salida
  
  // Rutas relativas
  static const String workspaceFolderName = 'workspace';
  static const String nodeFolderPath = 'Node';
  static const String nodeExecutableName = 'node.exe';
  static const String scriptCompraFolderName = 'ScriptCompra';
  static const String configFileName = 'config.json';
  
  // Scripts
  static const List<String> requiredScripts = [
    'boletoSencillo.ts',
    'boletoRedondo.ts',
    'boletoAbierto.ts',
  ];
  
  // Validaciones
  static const int maxLogSize = 1000000; // 1MB máximo para logs
  static const int maxTerminalLines = 5000; // Máximo de líneas en terminal
  
  // UI
  static const String appTitle = 'Estrella Roja - Bot de Compra de Boletos';
  static const String appVersion = '1.2.0';
  
  // GitHub Updates
  static const String githubRepo = 'NRVH/automatizacion-qa-ui';
  static const String githubRepoUrl = 'https://github.com/NRVH/automatizacion-qa-ui';
  static const String githubReleasesUrl = 'https://github.com/NRVH/automatizacion-qa-ui/releases';
  static const Duration updateCheckInterval = Duration(hours: 4); // Verificar cada 4 horas
  static const bool checkUpdatesOnStartup = true; // Verificar al iniciar la app
  
  // Mensajes de error comunes
  static const String errorNoGit = 'Git no está instalado. Descárgalo de: https://git-scm.com/download/win';
  static const String errorNoRepo = 'Repositorio no clonado. Ve a la pestaña Git y clónalo primero.';
  static const String errorNoConnection = 'Sin conexión a internet. Verifica tu red.';
  static const String errorInvalidCredentials = 'Credenciales inválidas. Verifica usuario y contraseña.';
  
  // Info
  static const String supportUrl = 'http://gitlab.estrellaroja.com.mx/java/estrella-roja-qa-automatizacion/-/issues';
}
