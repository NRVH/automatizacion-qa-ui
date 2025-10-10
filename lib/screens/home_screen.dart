import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state_provider.dart';
import 'config_editor_screen.dart';
import 'git_settings_screen.dart';
import 'execution_screen.dart';
import '../widgets/workspace_health_widget.dart';
import '../widgets/update_dialog.dart';
import '../constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ExecutionScreen(),
    const ConfigEditorScreen(),
    const GitSettingsScreen(),
  ];

  void _showUpdateDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      barrierDismissible: !appState.availableUpdate!.isMandatory,
      builder: (context) => UpdateDialog(
        updateInfo: appState.availableUpdate!,
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, AppStateProvider appState) async {
    await appState.checkForUpdates(silent: false);
    
    if (!context.mounted) return;

    if (appState.hasAvailableUpdate) {
      _showUpdateDialog(context, appState);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay actualizaciones disponibles. Tienes la última versión.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openGitHubRepo() async {
    final url = Uri.parse(AppConstants.githubRepoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Estrella Roja - Bot de Compra'),
          ],
        ),
        actions: [
          // Botón de actualizaciones
          Stack(
            children: [
              IconButton(
                onPressed: appState.hasAvailableUpdate
                    ? () => _showUpdateDialog(context, appState)
                    : () => _checkForUpdates(context, appState),
                icon: Icon(
                  appState.hasAvailableUpdate
                      ? Icons.system_update
                      : Icons.system_update_outlined,
                  color: appState.hasAvailableUpdate ? Colors.orange : null,
                ),
                tooltip: appState.hasAvailableUpdate
                    ? 'Actualización disponible'
                    : 'Buscar actualizaciones',
              ),
              if (appState.hasAvailableUpdate)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          
          // Menú de ayuda
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (value) {
              switch (value) {
                case 'check_updates':
                  _checkForUpdates(context, appState);
                  break;
                case 'github':
                  _openGitHubRepo();
                  break;
                case 'about':
                  showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appTitle,
                    applicationVersion: 'v${AppConstants.appVersion}',
                    applicationIcon: const Icon(
                      Icons.confirmation_number,
                      size: 48,
                      color: Colors.blue,
                    ),
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Interfaz gráfica para automatización de compra de boletos '
                        'de Estrella Roja usando Playwright.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Desarrollado para el equipo de QA',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'check_updates',
                child: Row(
                  children: [
                    Icon(Icons.system_update_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Buscar actualizaciones'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'github',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 12),
                    Text('Ver en GitHub'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Acerca de'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'v${AppConstants.appVersion} [TEST]',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Indicador de estado del repositorio
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: Icon(
                appState.isRepositoryCloned ? Icons.check_circle : Icons.warning,
                color: appState.isRepositoryCloned ? Colors.green : Colors.orange,
                size: 18,
              ),
              label: Text(
                appState.isRepositoryCloned ? 'Repo clonado' : 'Repo no clonado',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner de estado del workspace
                const WorkspaceHealthWidget(),
                // Contenido principal
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Ejecutar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Git',
          ),
        ],
      ),
    );
  }
}
