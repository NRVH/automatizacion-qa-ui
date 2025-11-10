import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/execution_instance.dart';
import '../models/config_model.dart';
import '../providers/app_state_provider.dart';
import '../services/script_executor_service.dart';
import 'execution_config_dialog.dart';

/// Contenido de un tab de ejecución individual
/// Muestra configuración, terminal y evidencias para una ejecución específica
class ExecutionTabContent extends StatefulWidget {
  final String executionId;

  const ExecutionTabContent({
    super.key,
    required this.executionId,
  });

  @override
  State<ExecutionTabContent> createState() => _ExecutionTabContentState();
}

class _ExecutionTabContentState extends State<ExecutionTabContent> {
  AvailableScript? _selectedScript;
  List<AvailableScript> _availableScripts = [];
  bool _loadingScripts = true;
  final ScrollController _terminalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAvailableScripts();
  }

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableScripts() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    if (!appState.isRepositoryCloned) {
      setState(() {
        _loadingScripts = false;
      });
      return;
    }

    try {
      final scripts = await appState.scriptService.getAvailableScripts();
      final execution = appState.getExecution(widget.executionId);
      
      setState(() {
        _availableScripts = scripts;
        
        // Intentar pre-seleccionar el script de la ejecución
        if (execution != null && scripts.isNotEmpty) {
          final matchingScript = scripts.firstWhere(
            (s) => s.name == execution.scriptName,
            orElse: () => scripts.first,
          );
          _selectedScript = matchingScript;
        } else if (scripts.isNotEmpty) {
          _selectedScript = scripts.first;
        }
        
        _loadingScripts = false;
      });
    } catch (e) {
      setState(() {
        _loadingScripts = false;
      });
    }
  }

  void _scrollTerminalToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeScript() async {
    if (_selectedScript == null) {
      _showError('Selecciona un script primero');
      return;
    }

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final execution = appState.getExecution(widget.executionId);
    
    if (execution == null) return;

    // Validar que no esté ya ejecutándose
    if (execution.status == ExecutionStatus.running) {
      _showError('Esta ejecución ya está en progreso');
      return;
    }

    try {
      // Marcar como iniciada
      appState.markExecutionAsStarted(widget.executionId);
      
      // Limpiar logs previos
      execution.logs.clear();
      
      // Escribir configuración temporal para esta ejecución
      final configPath = await appState.configService.writeTemporaryConfig(
        execution.config,
        widget.executionId,
      );
      
      // Ejecutar script con ScriptExecutorService
      await appState.scriptService.executeScriptWithId(
        executionId: widget.executionId,
        scriptName: _selectedScript!.name,
        displayName: _selectedScript!.displayName,
        evidencePath: execution.evidencePath,
        configPath: configPath,
        onOutput: (line) {
          appState.addExecutionLog(widget.executionId, line);
          _scrollTerminalToBottom();
        },
        onScreenshotDetected: (screenshotPath) {
          appState.incrementExecutionScreenshots(widget.executionId);
        },
        onComplete: () {
          if (mounted) {
            appState.markExecutionAsCompleted(widget.executionId);
          }
        },
        onError: (error) {
          if (mounted) {
            appState.markExecutionAsFailed(widget.executionId, error.toString());
          }
        },
      );
      
    } catch (e) {
      if (mounted) {
        appState.markExecutionAsFailed(widget.executionId, e.toString());
        _showError('Error ejecutando script: $e');
      }
    }
  }

  Future<void> _stopExecution() async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Detener Ejecución'),
          ],
        ),
        content: const Text(
          '¿Deseas detener esta ejecución?\n\n'
          'El proceso terminará inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Detener'),
          ),
        ],
      ),
    );

    if (shouldStop == true && mounted) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // Detener proceso real
      final stopped = await appState.scriptService.stopExecution(widget.executionId);
      
      if (stopped) {
        appState.markExecutionAsCancelled(widget.executionId);
      } else {
        _showError('No se pudo detener la ejecución');
      }
    }
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
        final execution = appState.getExecution(widget.executionId);
        
        if (execution == null) {
          return const Center(
            child: Text('Ejecución no encontrada'),
          );
        }

        return Row(
          children: [
            // Panel izquierdo: Configuración y control
            Expanded(
              flex: 3,
              child: _buildControlPanel(execution, appState),
            ),
            
            const VerticalDivider(width: 1),
            
            // Panel derecho: Terminal y evidencias
            Expanded(
              flex: 5,
              child: _buildOutputPanel(execution),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlPanel(ExecutionInstance execution, AppStateProvider appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado compacto en una sola línea
          _buildCompactStatus(execution),
          
          const SizedBox(height: 16),
          
          // Selector de script
          _buildScriptSelector(execution),
          
          const SizedBox(height: 16),
          
          // Información de configuración con botón editar
          _buildConfigInfo(execution, appState),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          _buildActionButtons(execution),
        ],
      ),
    );
  }

  Widget _buildCompactStatus(ExecutionInstance execution) {
    Color statusColor;
    switch (execution.status) {
      case ExecutionStatus.idle:
        statusColor = Colors.grey;
        break;
      case ExecutionStatus.running:
        statusColor = Colors.blue;
        break;
      case ExecutionStatus.completed:
        statusColor = Colors.green;
        break;
      case ExecutionStatus.failed:
        statusColor = Colors.red;
        break;
      case ExecutionStatus.cancelled:
        statusColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            execution.statusIcon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            execution.status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontSize: 12,
            ),
          ),
          if (execution.duration != null) ...[
            const SizedBox(width: 12),
            Text(
              '${execution.duration!.inSeconds}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (execution.screenshotCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '📸 ${execution.screenshotCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScriptSelector(ExecutionInstance execution) {
    if (_loadingScripts) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_availableScripts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('No hay scripts disponibles'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadAvailableScripts,
                child: const Text('Recargar'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Script',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AvailableScript>(
              value: _selectedScript,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _availableScripts.map((script) {
                return DropdownMenuItem(
                  value: script,
                  child: Text(script.name),
                );
              }).toList(),
              onChanged: execution.status == ExecutionStatus.running 
                  ? null 
                  : (value) {
                      setState(() {
                        _selectedScript = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInfo(ExecutionInstance execution, AppStateProvider appState) {
    final config = execution.config;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Configuración',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: execution.status == ExecutionStatus.running
                      ? null
                      : () => _editConfiguration(execution, appState),
                  tooltip: 'Editar configuración',
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow('Navegador:', config.navegador, Icons.web),
            const SizedBox(height: 8),
            _buildInfoRow('Origen:', config.origen, Icons.location_on),
            const SizedBox(height: 8),
            _buildInfoRow('Destino:', config.destino, Icons.place),
            const SizedBox(height: 8),
            _buildInfoRow('Tipo:', config.tipoBoleto, Icons.confirmation_number),
            const SizedBox(height: 8),
            _buildInfoRow('Pasajero:', '${config.passenger.name} ${config.passenger.lastnames}', Icons.person),
            const SizedBox(height: 8),
            _buildInfoRow('Email:', config.passenger.email, Icons.email),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _editConfiguration(ExecutionInstance execution, AppStateProvider appState) async {
    final newConfig = await showDialog<ConfigModel>(
      context: context,
      builder: (context) => ExecutionConfigDialog(
        initialConfig: execution.config,
      ),
    );

    if (newConfig != null) {
      // Actualizar la configuración de esta ejecución específica
      final updatedExecution = execution.copyWith(config: newConfig);
      appState.updateExecution(execution.id, updatedExecution);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(ExecutionInstance execution) {
    final isRunning = execution.status == ExecutionStatus.running;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isRunning ? null : _executeScript,
          icon: const Icon(Icons.play_arrow),
          label: const Text('EJECUTAR SCRIPT'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (isRunning) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _stopExecution,
            icon: const Icon(Icons.stop),
            label: const Text('DETENER'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOutputPanel(ExecutionInstance execution) {
    return Column(
      children: [
        // Terminal
        Expanded(
          flex: 3,
          child: _buildTerminal(execution),
        ),
        
        const Divider(height: 1),
        
        // Panel de evidencias (placeholder por ahora)
        Expanded(
          flex: 2,
          child: _buildEvidencesPanel(execution),
        ),
      ],
    );
  }

  Widget _buildTerminal(ExecutionInstance execution) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header del terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'TERMINAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (execution.logs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: Colors.white70,
                    onPressed: () => _copyLogsToClipboard(execution),
                    tooltip: 'Copiar logs',
                  ),
              ],
            ),
          ),
          
          // Contenido del terminal
          Expanded(
            child: execution.logs.isEmpty
                ? const Center(
                    child: Text(
                      'Esperando ejecución...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: _terminalScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: execution.logs.length,
                    itemBuilder: (context, index) {
                      return SelectableText(
                        execution.logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencesPanel(ExecutionInstance execution) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_library, size: 20),
                const SizedBox(width: 8),
                Text(
                  'EVIDENCIAS (${execution.screenshotCount})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (execution.screenshotCount > 0) ...[
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: () {
                      // TODO: Descargar evidencias
                    },
                    tooltip: 'Descargar ZIP',
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, size: 20),
                    onPressed: () {
                      // TODO: Abrir carpeta
                    },
                    tooltip: 'Abrir carpeta',
                  ),
                ],
              ],
            ),
          ),
          
          // Contenido (placeholder)
          Expanded(
            child: execution.screenshotCount == 0
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No hay evidencias aún',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: execution.screenshotCount,
                    itemBuilder: (context, index) {
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 48),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black54,
                                child: Text(
                                  'Captura ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLogsToClipboard(ExecutionInstance execution) async {
    await Clipboard.setData(
      ClipboardData(text: execution.logs.join('\n')),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copiados al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
