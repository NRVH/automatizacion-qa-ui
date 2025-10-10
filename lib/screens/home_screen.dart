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

  void _showAboutDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.confirmation_number,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                AppConstants.appTitle,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Versión actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  'Versión ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              const Text(
                'Interfaz gráfica para automatización de compra de boletos de Estrella Roja usando Playwright.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Desarrollado para el equipo de QA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              // Notas de la versión
              Row(
                children: [
                  Icon(Icons.new_releases, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Novedades de esta versión',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Changelog
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChangelogItem(
                      icon: Icons.auto_fix_high,
                      text: 'Menú simplificado sin opciones técnicas',
                    ),
                    SizedBox(height: 8),
                    _ChangelogItem(
                      icon: Icons.info,
                      text: 'Diálogo "Acerca de" mejorado con notas de versión',
                    ),
                    SizedBox(height: 8),
                    _ChangelogItem(
                      icon: Icons.update,
                      text: 'Sistema de actualización automática mejorado',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
              if (value == 'about') {
                _showAboutDialog(context, appState);
              }
            },
            itemBuilder: (context) => [
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
                      'v${AppConstants.appVersion}',
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

// Widget helper para items del changelog
class _ChangelogItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChangelogItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
