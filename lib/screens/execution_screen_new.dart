import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/execution_tab_content.dart';

class ExecutionScreen extends StatefulWidget {
  const ExecutionScreen({super.key});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _initializeWithFirstTab();
  }

  void _initializeWithFirstTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // Si no hay ejecuciones, crear una por defecto
      if (appState.executions.isEmpty) {
        _createNewTab();
      } else {
        _rebuildTabController(appState);
      }
    });
  }

  void _rebuildTabController(AppStateProvider appState) {
    final executions = appState.executionsList;
    
    if (executions.isEmpty) {
      _tabController?.dispose();
      _tabController = null;
      return;
    }

    final currentIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    
    _tabController = TabController(
      length: executions.length,
      vsync: this,
      initialIndex: currentIndex.clamp(0, executions.length - 1),
    );

    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        final execution = executions[_tabController!.index];
        appState.setActiveExecution(execution.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _createNewTab() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Validar límite
    if (!appState.canCreateNewExecution) {
      _showError('Máximo ${AppStateProvider.maxExecutions} ejecuciones simultáneas');
      return;
    }

    // Validar que el repositorio esté clonado
    if (!appState.isRepositoryCloned) {
      _showError('Primero debes clonar el repositorio en la pestaña Git');
      return;
    }

    final scriptName = await _selectScriptDialog();
    if (scriptName == null) return;

    final executionId = await appState.createNewExecution(
      scriptName: scriptName,
      config: appState.config,
    );

    if (executionId != null && mounted) {
      setState(() {
        _rebuildTabController(appState);
        // Cambiar al nuevo tab
        final newIndex = appState.executionsList.length - 1;
        _tabController?.animateTo(newIndex);
      });
    }
  }

  Future<String?> _selectScriptDialog() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Obtener scripts disponibles
    final scripts = await appState.scriptService.getAvailableScripts();
    
    if (scripts.isEmpty) {
      _showError('No hay scripts disponibles');
      return null;
    }

    if (!mounted) return null;

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Script'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: scripts.map((script) {
              return ListTile(
                title: Text(script.name),
                subtitle: Text(script.path),
                onTap: () => Navigator.pop(context, script.name),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _closeTab(String executionId) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final execution = appState.getExecution(executionId);
    
    if (execution == null) return;

    // Validar si puede cerrarse
    if (!execution.canClose) {
      _showError('No puedes cerrar una ejecución en progreso');
      return;
    }

    // Confirmar cierre
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Ejecución'),
        content: Text('¿Cerrar "${execution.shortDisplayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final success = appState.removeExecution(executionId);
              if (success && mounted) {
                setState(() {
                  _rebuildTabController(appState);
                });
              }
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final executions = appState.executionsList;
        
        // Actualizar TabController si cambió el número de ejecuciones
        if (_tabController == null || _tabController!.length != executions.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _rebuildTabController(appState);
              });
            }
          });
        }

        if (executions.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Barra de tabs
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tabs
                  if (_tabController != null)
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: executions.map((exec) {
                          return Tab(
                            child: Row(
                              children: [
                                Text(exec.statusIcon),
                                const SizedBox(width: 6),
                                Text(exec.shortDisplayName),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _closeTab(exec.id),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Botón [+]
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: appState.canCreateNewExecution ? _createNewTab : null,
                    tooltip: appState.canCreateNewExecution 
                        ? 'Nueva ejecución' 
                        : 'Máximo ${AppStateProvider.maxExecutions} ejecuciones',
                  ),
                  
                  // Botón limpiar completadas
                  if (executions.any((e) => e.status != ExecutionStatus.running))
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: () {
                        final count = appState.clearCompletedExecutions();
                        if (count > 0 && mounted) {
                          setState(() {
                            _rebuildTabController(appState);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$count ejecuciones cerradas')),
                          );
                        }
                      },
                      tooltip: 'Cerrar completadas',
                    ),
                ],
              ),
            ),
            
            // Contenido de los tabs
            Expanded(
              child: _tabController != null
                  ? TabBarView(
                      controller: _tabController,
                      children: executions.map((exec) {
                        return ExecutionTabContent(
                          key: ValueKey(exec.id),
                          executionId: exec.id,
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ejecuciones',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una nueva ejecución para empezar',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createNewTab,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Ejecución'),
          ),
        ],
      ),
    );
  }
}
