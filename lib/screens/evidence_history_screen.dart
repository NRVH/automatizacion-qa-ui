import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/image_viewer_dialog.dart';

class EvidenceHistoryScreen extends StatefulWidget {
  const EvidenceHistoryScreen({super.key});

  @override
  State<EvidenceHistoryScreen> createState() => _EvidenceHistoryScreenState();
}

class _EvidenceHistoryScreenState extends State<EvidenceHistoryScreen> {
  List<EvidenceFolder> _evidenceFolders = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // 'date', 'name', 'size'
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadEvidenceFolders();
  }

  Future<void> _loadEvidenceFolders() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final workspacePath = await appState.gitService.getWorkspacePath();
      
      final evidencesDir = Directory(path.join(workspacePath, 'evidencias'));
      
      if (!evidencesDir.existsSync()) {
        setState(() {
          _evidenceFolders = [];
          _isLoading = false;
        });
        return;
      }

      final folders = <EvidenceFolder>[];
      
      await for (var entity in evidencesDir.list()) {
        if (entity is Directory) {
          final folderInfo = await _getEvidenceFolderInfo(entity);
          folders.add(folderInfo);
        }
      }

      _sortFolders(folders);

      setState(() {
        _evidenceFolders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando historial: $e');
    }
  }

  Future<EvidenceFolder> _getEvidenceFolderInfo(Directory dir) async {
    final stats = await dir.stat();
    final files = await dir
        .list()
        .where((f) => f is File && _isImageFile(f.path))
        .toList();
    
    final imageFiles = files.cast<File>();
    
    // Calcular tamaño total
    int totalSize = 0;
    for (var file in imageFiles) {
      final stat = await file.stat();
      totalSize += stat.size;
    }

    // Extraer nombre del script y fecha del nombre de carpeta
    final folderName = path.basename(dir.path);
    final parts = folderName.split('_');
    
    String scriptName = 'Desconocido';
    DateTime? executionDate;
    
    if (parts.length >= 3) {
      scriptName = parts[0];
      try {
        final datePart = parts[1];
        final timePart = parts[2];
        executionDate = DateTime.parse('$datePart $timePart'.replaceAll('-', ':'));
      } catch (e) {
        executionDate = stats.modified;
      }
    } else {
      executionDate = stats.modified;
    }

    return EvidenceFolder(
      path: dir.path,
      name: folderName,
      scriptName: scriptName,
      executionDate: executionDate,
      imageCount: imageFiles.length,
      totalSize: totalSize,
      imagePaths: imageFiles.map((f) => f.path).toList(),
    );
  }

  bool _isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ext == '.png' || ext == '.jpg' || ext == '.jpeg';
  }

  void _sortFolders(List<EvidenceFolder> folders) {
    switch (_sortBy) {
      case 'date':
        folders.sort((a, b) => _sortDescending
            ? b.executionDate.compareTo(a.executionDate)
            : a.executionDate.compareTo(b.executionDate));
        break;
      case 'name':
        folders.sort((a, b) => _sortDescending
            ? b.scriptName.compareTo(a.scriptName)
            : a.scriptName.compareTo(b.scriptName));
        break;
      case 'size':
        folders.sort((a, b) => _sortDescending
            ? b.totalSize.compareTo(a.totalSize)
            : a.totalSize.compareTo(b.totalSize));
        break;
    }
  }

  Future<void> _deleteFolder(EvidenceFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Eliminar Evidencias'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de eliminar estas evidencias?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Script: ${folder.scriptName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Imágenes: ${folder.imageCount}'),
                  Text('Tamaño: ${_formatBytes(folder.totalSize)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Directory(folder.path).delete(recursive: true);
        _loadEvidenceFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evidencias eliminadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error eliminando carpeta: $e');
      }
    }
  }

  Future<void> _deleteOldFolders(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final oldFolders = _evidenceFolders
        .where((f) => f.executionDate.isBefore(cutoffDate))
        .toList();

    if (oldFolders.isEmpty) {
      _showInfo('No hay evidencias anteriores a $days días');
      return;
    }

    final totalSize = oldFolders.fold<int>(0, (sum, f) => sum + f.totalSize);
    final totalImages = oldFolders.fold<int>(0, (sum, f) => sum + f.imageCount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 12),
            Text('Limpieza Automática'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se eliminarán ${oldFolders.length} carpetas anteriores a $days días:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📁 Carpetas: ${oldFolders.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('🖼️ Imágenes: $totalImages'),
                  Text('💾 Espacio: ${_formatBytes(totalSize)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int deleted = 0;
      for (var folder in oldFolders) {
        try {
          await Directory(folder.path).delete(recursive: true);
          deleted++;
        } catch (e) {
          // Continuar con las demás
        }
      }
      
      _loadEvidenceFolders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deleted carpetas eliminadas (${_formatBytes(totalSize)} liberados)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} días atrás';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = _evidenceFolders.fold<int>(0, (sum, f) => sum + f.totalSize);
    final totalImages = _evidenceFolders.fold<int>(0, (sum, f) => sum + f.imageCount);

    return Scaffold(
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Historial de Evidencias',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadEvidenceFolders,
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      Icons.folder,
                      '${_evidenceFolders.length} carpetas',
                      Colors.purple,
                    ),
                    _buildStatChip(
                      Icons.image,
                      '$totalImages imágenes',
                      Colors.orange,
                    ),
                    _buildStatChip(
                      Icons.storage,
                      _formatBytes(totalSize),
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Text('Ordenar por:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'date', label: Text('Fecha'), icon: Icon(Icons.calendar_today, size: 16)),
                    ButtonSegment(value: 'name', label: Text('Nombre'), icon: Icon(Icons.abc, size: 16)),
                    ButtonSegment(value: 'size', label: Text('Tamaño'), icon: Icon(Icons.storage, size: 16)),
                  ],
                  selected: {_sortBy},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _sortBy = newSelection.first;
                      _sortFolders(_evidenceFolders);
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                  onPressed: () {
                    setState(() {
                      _sortDescending = !_sortDescending;
                      _sortFolders(_evidenceFolders);
                    });
                  },
                  tooltip: _sortDescending ? 'Descendente' : 'Ascendente',
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Limpiar > 5 días'),
                  onPressed: () => _deleteOldFolders(5),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Limpiar > 7 días'),
                  onPressed: () => _deleteOldFolders(7),
                ),
              ],
            ),
          ),

          // Lista de carpetas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _evidenceFolders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay evidencias guardadas',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _evidenceFolders.length,
                        itemBuilder: (context, index) {
                          return _buildFolderCard(_evidenceFolders[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildFolderCard(EvidenceFolder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.folder, color: Colors.blue[700]),
        ),
        title: Text(
          folder.scriptName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatDate(folder.executionDate)),
            const SizedBox(height: 2),
            Text(
              '${folder.imageCount} imágenes • ${_formatBytes(folder.totalSize)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.folder_open, size: 20),
              onPressed: () async {
                try {
                  await Process.run('explorer', [folder.path.replaceAll('/', '\\')]);
                } catch (e) {
                  _showError('Error abriendo carpeta: $e');
                }
              },
              tooltip: 'Abrir carpeta',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteFolder(folder),
              tooltip: 'Eliminar',
            ),
          ],
        ),
        children: [
          if (folder.imagePaths.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay imágenes en esta carpeta'),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.3,
                ),
                itemCount: folder.imagePaths.length,
                itemBuilder: (context, index) {
                  final imagePath = folder.imagePaths[index];
                  return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ImageViewerDialog(
                          imagePaths: folder.imagePaths,
                          initialIndex: index,
                        ),
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class EvidenceFolder {
  final String path;
  final String name;
  final String scriptName;
  final DateTime executionDate;
  final int imageCount;
  final int totalSize;
  final List<String> imagePaths;

  EvidenceFolder({
    required this.path,
    required this.name,
    required this.scriptName,
    required this.executionDate,
    required this.imageCount,
    required this.totalSize,
    required this.imagePaths,
  });
}
