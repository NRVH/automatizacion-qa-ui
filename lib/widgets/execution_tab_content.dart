import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import '../models/execution_instance.dart';
import '../models/config_model.dart';
import '../providers/app_state_provider.dart';
import '../services/script_executor_service.dart';
import 'execution_config_dialog.dart';
import 'image_viewer_dialog.dart';

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
  bool _videosExpanded = false;
  bool _screenshotsExpanded = false;

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
      if (mounted) {
        setState(() {
          _loadingScripts = false;
        });
      }
      return;
    }

    try {
      final scripts = await appState.scriptService.getAvailableScripts();
      final execution = appState.getExecution(widget.executionId);
      
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingScripts = false;
        });
      }
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
    return Selector<AppStateProvider, ExecutionInstance?>(
      selector: (context, appState) => appState.getExecution(widget.executionId),
      shouldRebuild: (previous, next) {
        // Solo reconstruir si cambió el estado, no los logs
        if (previous == null && next == null) return false;
        if (previous == null || next == null) return true;
        
        return previous.status != next.status ||
               previous.config != next.config ||
               previous.screenshotCount != next.screenshotCount;
      },
      builder: (context, execution, child) {
        if (execution == null) {
          return const Center(
            child: Text('Ejecución no encontrada'),
          );
        }

        final appState = Provider.of<AppStateProvider>(context, listen: false);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinear al inicio (arriba)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular tamaños responsivos basados en altura disponible
        final isLargeScreen = constraints.maxHeight > 800;
        final baseFontSize = isLargeScreen ? 13.0 : 11.0;
        final titleFontSize = isLargeScreen ? 15.0 : 13.0;
        final iconSize = isLargeScreen ? 18.0 : 14.0;
        final padding = isLargeScreen ? 16.0 : 12.0;
        final spacing = isLargeScreen ? 16.0 : 12.0;
        
        return Align(
          alignment: Alignment.topCenter, // Forzar alineación superior
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min, // No expandir verticalmente
              children: [
                // Estado compacto en una sola línea
                _buildCompactStatus(execution, baseFontSize, iconSize),
                
                SizedBox(height: spacing),
                
                // Selector de script
                _buildScriptSelector(execution, baseFontSize, titleFontSize, padding),
                
                SizedBox(height: spacing),
                
                // Información de configuración con botón editar
                _buildConfigInfo(execution, appState, baseFontSize, titleFontSize, iconSize, padding),
                
                SizedBox(height: spacing),
                
                // Botones de acción
                _buildActionButtons(execution, baseFontSize, iconSize, padding),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatus(ExecutionInstance execution, double fontSize, double iconSize) {
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
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            execution.statusIcon,
            style: TextStyle(fontSize: iconSize),
          ),
          SizedBox(width: fontSize * 0.5),
          Text(
            execution.status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: statusColor,
              fontSize: fontSize,
            ),
          ),
          if (execution.duration != null) ...[
            SizedBox(width: fontSize * 0.7),
            Text('⏱', style: TextStyle(fontSize: iconSize * 0.85)),
            SizedBox(width: fontSize * 0.2),
            Text(
              '${execution.duration!.inSeconds}s',
              style: TextStyle(fontSize: fontSize),
            ),
          ],
          if (execution.screenshotCount > 0) ...[
            SizedBox(width: fontSize * 0.7),
            Text(
              '📸 ${execution.screenshotCount}',
              style: TextStyle(fontSize: fontSize),
            ),
          ],
          // Contador de videos (contado en tiempo real del directorio)
          Builder(
            builder: (context) {
              final evidenceDir = Directory(execution.evidencePath);
              if (!evidenceDir.existsSync()) return const SizedBox.shrink();
              
              final videoCount = evidenceDir
                  .listSync()
                  .where((entity) => entity is File && _isVideoFile(entity.path))
                  .length;
              
              if (videoCount > 0) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: fontSize * 0.7),
                    Text(
                      '🎥 $videoCount',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScriptSelector(ExecutionInstance execution, double fontSize, double titleSize, double padding) {
    if (_loadingScripts) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_availableScripts.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: fontSize * 1.7),
              SizedBox(height: fontSize * 0.5),
              Text('No hay scripts disponibles', style: TextStyle(fontSize: fontSize)),
              SizedBox(height: fontSize * 0.5),
              TextButton(
                onPressed: _loadAvailableScripts,
                child: Text('Recargar', style: TextStyle(fontSize: fontSize)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Script',
              style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: fontSize * 0.5),
            DropdownButtonFormField<AvailableScript>(
              value: _selectedScript,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: padding * 0.8, vertical: fontSize * 0.5),
                isDense: true,
              ),
              items: _availableScripts.map((script) {
                return DropdownMenuItem(
                  value: script,
                  child: Text(script.name, style: TextStyle(fontSize: fontSize)),
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

  Widget _buildConfigInfo(ExecutionInstance execution, AppStateProvider appState, 
      double fontSize, double titleSize, double iconSize, double padding) {
    final config = execution.config;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Configuración',
                  style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, size: iconSize),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: execution.status == ExecutionStatus.running
                      ? null
                      : () => _editConfiguration(execution, appState),
                  tooltip: 'Editar configuración',
                ),
              ],
            ),
            Divider(height: padding),
            _buildInfoRow('Navegador:', config.navegador, Icons.web, fontSize, iconSize),
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow('Origen:', config.origen, Icons.location_on, fontSize, iconSize),
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow('Destino:', config.destino, Icons.place, fontSize, iconSize),
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow('Tipo:', config.tipoBoleto, Icons.confirmation_number, fontSize, iconSize),
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow('Pasajero:', '${config.passenger.name} ${config.passenger.lastnames}', Icons.person, fontSize, iconSize),
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow('Email:', config.passenger.email, Icons.email, fontSize, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, double fontSize, double iconSize) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: Colors.grey[600]),
        SizedBox(width: fontSize * 0.5),
        SizedBox(
          width: fontSize * 6.5,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _editConfiguration(ExecutionInstance execution, AppStateProvider appState) async {
    // Usar el script actualmente seleccionado en el dropdown, no el de la ejecución
    final scriptInfo = _selectedScript ?? _availableScripts.firstWhere(
      (s) => s.name == execution.scriptName,
      orElse: () => AvailableScript(
        name: execution.scriptName,
        fileName: '${execution.scriptName}.ts',
        displayName: execution.scriptName,
        isPlatformaDigital: false, // Default si no se encuentra
      ),
    );

    final newConfig = await showDialog<ConfigModel>(
      context: context,
      builder: (context) => ExecutionConfigDialog(
        initialConfig: execution.config,
        isPlatformaDigital: scriptInfo.isPlatformaDigital,
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

  Widget _buildActionButtons(ExecutionInstance execution, double fontSize, double iconSize, double padding) {
    final isRunning = execution.status == ExecutionStatus.running;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isRunning ? null : _executeScript,
          icon: Icon(Icons.play_arrow, size: iconSize * 1.2),
          label: Text('EJECUTAR SCRIPT', style: TextStyle(fontSize: fontSize)),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: padding),
          ),
        ),
        if (isRunning) ...[
          SizedBox(height: fontSize * 0.5),
          OutlinedButton.icon(
            onPressed: _stopExecution,
            icon: Icon(Icons.stop, size: iconSize * 1.2),
            label: Text('DETENER', style: TextStyle(fontSize: fontSize)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(vertical: padding),
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
    return Selector<AppStateProvider, int>(
      selector: (context, appState) {
        final exec = appState.getExecution(widget.executionId);
        return exec?.logs.length ?? 0;
      },
      builder: (context, logCount, child) {
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
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvidencesPanel(ExecutionInstance execution) {
    return Selector<AppStateProvider, String>(
      selector: (context, appState) => '${execution.status}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      builder: (context, statusKey, child) {
        final evidenceDir = Directory(execution.evidencePath);
        
        return StreamBuilder<FileSystemEvent>(
          key: ValueKey('evidence_${execution.evidencePath}_$statusKey'),
          stream: evidenceDir.existsSync() 
              ? evidenceDir.watch(events: FileSystemEvent.all)
              : const Stream.empty(),
          builder: (context, snapshot) {
            // Obtener lista de imágenes y videos en la carpeta de evidencias
            List<FileSystemEntity> imageFiles = [];
            List<FileSystemEntity> videoFiles = [];
        
        if (evidenceDir.existsSync()) {
          final allFiles = evidenceDir.listSync().where((file) => file is File).toList();
          
          imageFiles = allFiles
              .where((file) => _isImageFile(file.path))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
          
          videoFiles = allFiles
              .where((file) => _isVideoFile(file.path))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
        }

        final totalFiles = imageFiles.length + videoFiles.length;

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
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'EVIDENCIAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                if (imageFiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${imageFiles.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (imageFiles.isNotEmpty && videoFiles.isNotEmpty)
                  const SizedBox(width: 8),
                if (videoFiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${videoFiles.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (imageFiles.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: () => _downloadEvidencesAsZip(execution, imageFiles),
                    tooltip: 'Descargar ZIP',
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, size: 20),
                    onPressed: () => _openEvidenceFolder(execution),
                    tooltip: 'Abrir carpeta',
                  ),
                ],
              ],
            ),
          ),
          
          // Grid de evidencias (imágenes y videos)
          Expanded(
            child: totalFiles == 0
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Sección de Videos (si existen)
                      if (videoFiles.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _videosExpanded = !_videosExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _videosExpanded ? Icons.expand_more : Icons.chevron_right,
                                  size: 24,
                                  color: Colors.red[700],
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.videocam, size: 20, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Videos (${videoFiles.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_videosExpanded) ...[
                          const SizedBox(height: 12),
                          ...videoFiles.map((videoFile) {
                          final file = videoFile as File;
                          final fileName = path.basename(file.path);
                          final fileSize = file.lengthSync();
                          final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.red[700],
                                  size: 32,
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('$fileSizeMB MB'),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _openVideo(file.path),
                                tooltip: 'Reproducir video',
                              ),
                            ),
                          );
                        }),
                        ],
                        const SizedBox(height: 24),
                      ],
                      
                      // Sección de Imágenes (si existen)
                      if (imageFiles.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _screenshotsExpanded = !_screenshotsExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _screenshotsExpanded ? Icons.expand_more : Icons.chevron_right,
                                  size: 24,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.photo_library, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Screenshots (${imageFiles.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_screenshotsExpanded) ...[
                          const SizedBox(height: 12),
                          GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: imageFiles.length,
                          itemBuilder: (context, index) {
                            final file = imageFiles[index] as File;
                            final fileName = path.basename(file.path);
                            
                            return InkWell(
                              onTap: () => _openImageViewer(
                                imageFiles.map((f) => f.path).toList(),
                                index,
                              ),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Preview de la imagen
                                    Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, size: 48),
                                        );
                                      },
                                    ),
                                    // Overlay con nombre
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black87,
                                              Colors.black54,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          fileName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
          },
        );
      },
    );
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.png' || extension == '.jpg' || extension == '.jpeg';
  }

  bool _isVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.webm' || extension == '.mp4';
  }

  void _openImageViewer(List<String> imagePaths, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerDialog(
        imagePaths: imagePaths,
        initialIndex: initialIndex,
      ),
    );
  }

  Future<void> _openVideo(String videoPath) async {
    try {
      // Normalizar la ruta para Windows
      final normalizedPath = videoPath.replaceAll('/', '\\');
      
      // Usar el reproductor predeterminado del sistema
      await Process.run('cmd', ['/c', 'start', '', normalizedPath], runInShell: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEvidenceFolder(ExecutionInstance execution) async {
    final evidenceDir = Directory(execution.evidencePath);
    
    if (!evidenceDir.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La carpeta de evidencias no existe'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Normalizar la ruta para Windows (convertir / a \)
      final normalizedPath = evidenceDir.path.replaceAll('/', '\\');
      
      // Usar explorer de Windows para abrir la carpeta específica
      await Process.run('explorer', [normalizedPath]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir carpeta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadEvidencesAsZip(
    ExecutionInstance execution,
    List<FileSystemEntity> imageFiles,
  ) async {
    if (imageFiles.isEmpty) return;

    try {
      // Pedir al usuario dónde guardar el ZIP
      final fileName = '${execution.scriptName}_${execution.id}.zip';
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar evidencias',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath == null) return; // Usuario canceló

      // Mostrar indicador de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Creando archivo ZIP...'),
              ],
            ),
          ),
        );
      }

      // Crear archivo ZIP
      final archive = Archive();
      
      for (final file in imageFiles) {
        if (file is File) {
          final bytes = await file.readAsBytes();
          final fileName = path.basename(file.path);
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
        }
      }

      // Guardar ZIP
      final encoder = ZipEncoder();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encoder.encode(archive)!);

      // Cerrar diálogo de progreso
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ZIP guardado: ${path.basename(outputPath)}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Abrir carpeta',
              textColor: Colors.white,
              onPressed: () {
                Process.run('explorer', ['/select,', outputPath]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear ZIP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
