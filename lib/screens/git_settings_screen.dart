import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class GitSettingsScreen extends StatefulWidget {
  const GitSettingsScreen({super.key});

  @override
  State<GitSettingsScreen> createState() => _GitSettingsScreenState();
}

class _GitSettingsScreenState extends State<GitSettingsScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _branchController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasCredentials = false;
  String _currentBranch = '';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _branchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    final hasCredentials = await appState.gitService.hasCredentials();
    final branch = await appState.gitService.getBranch();
    
    setState(() {
      _hasCredentials = hasCredentials;
      _currentBranch = branch;
      _branchController.text = branch;
    });

    if (hasCredentials) {
      final creds = await appState.gitService.getCredentials();
      _usernameController.text = creds['username'] ?? '';
      _passwordController.text = creds['password'] ?? '';
    }

    if (appState.isRepositoryCloned) {
      final currentBranch = await appState.gitService.getCurrentBranch();
      if (currentBranch != null) {
        setState(() {
          _currentBranch = currentBranch;
        });
      }
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    _scrollToBottom();
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveCredentials() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor ingresa usuario y contraseña');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      await appState.gitService.saveCredentials(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      await appState.gitService.saveBranch(_branchController.text);

      setState(() {
        _hasCredentials = true;
        _currentBranch = _branchController.text;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales guardadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error guardando credenciales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cloneRepository() async {
    if (!_hasCredentials) {
      _showError('Primero configura las credenciales de Git');
      return;
    }

    _clearLogs();
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      _addLog('Iniciando clonación del repositorio...');
      _addLog('URL: ${appState.gitService.repoUrl}');
      _addLog('Rama: $_currentBranch');
      _addLog('');

      await appState.gitService.cloneRepository(
        onOutput: _addLog,
        branch: _currentBranch,
      );

      appState.setRepositoryCloned(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repositorio clonado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('');
      _addLog('ERROR: $e');
      _showError('Error clonando repositorio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pullRepository() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    if (!appState.isRepositoryCloned) {
      _showError('Primero debes clonar el repositorio');
      return;
    }

    _clearLogs();
    setState(() => _isLoading = true);

    try {
      _addLog('Actualizando repositorio...');
      _addLog('');

      await appState.gitService.pullRepository(
        onOutput: _addLog,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repositorio actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('');
      _addLog('ERROR: $e');
      _showError('Error actualizando repositorio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeBranch() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    if (!appState.isRepositoryCloned) {
      _showError('Primero debes clonar el repositorio');
      return;
    }

    final newBranch = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _currentBranch);
        return AlertDialog(
          title: const Text('Cambiar de Rama'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre de la rama',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Cambiar'),
            ),
          ],
        );
      },
    );

    if (newBranch == null || newBranch.isEmpty || newBranch == _currentBranch) {
      return;
    }

    _clearLogs();
    setState(() => _isLoading = true);

    try {
      _addLog('Cambiando a rama: $newBranch');
      _addLog('');

      await appState.gitService.checkoutBranch(
        branch: newBranch,
        onOutput: _addLog,
      );

      setState(() {
        _currentBranch = newBranch;
        _branchController.text = newBranch;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rama cambiada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('');
      _addLog('ERROR: $e');
      _showError('Error cambiando de rama: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTokenInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('¿Cómo generar un Token de GitLab?'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sigue estos pasos para crear tu token de acceso personal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                _buildInstructionStep(
                  '1',
                  'Inicia sesión en GitLab',
                  'Ve a: http://gitlab.estrellaroja.com.mx/',
                ),
                
                _buildInstructionStep(
                  '2',
                  'Accede a tu perfil',
                  'Haz clic en tu avatar (esquina superior derecha) → Preferences',
                ),
                
                _buildInstructionStep(
                  '3',
                  'Crea el token',
                  'En el menú izquierdo, busca "Access Tokens" → Crea un nuevo token',
                ),
                
                _buildInstructionStep(
                  '4',
                  'Configura permisos',
                  'Dale un nombre (ej: "Bot QA") y selecciona el scope "read_repository"',
                ),
                
                _buildInstructionStep(
                  '5',
                  'Copia el token',
                  'Al crearlo, copia el token generado (empieza con glpat-)',
                ),
                
                _buildInstructionStep(
                  '6',
                  'Pégalo aquí',
                  'Usa ese token en el campo "Token de Acceso Personal"',
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'IMPORTANTE: Guarda el token en un lugar seguro. No podrás verlo nuevamente después de crearlo.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración de Git',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Configura las credenciales de GitLab para clonar y actualizar el repositorio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Credenciales
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Credenciales de GitLab',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_hasCredentials) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Configurado'),
                          avatar: Icon(Icons.check_circle, size: 18, color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Información importante sobre tokens
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Importante: Usa un Token de Acceso Personal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'GitLab requiere un token en lugar de tu contraseña regular.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _showTokenInstructions(),
                                icon: const Icon(Icons.help_outline, size: 18),
                                label: const Text('¿Cómo generar mi token?'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario de GitLab',
                      hintText: 'tu.usuario',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Token de Acceso Personal',
                      hintText: 'glpat-xxxxxxxxxxxxxxxxxxxx',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _branchController,
                    decoration: const InputDecoration(
                      labelText: 'Rama',
                      helperText: 'Rama a clonar/usar',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_tree),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveCredentials,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Credenciales'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Información del repositorio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Información del Repositorio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('URL:', appState.gitService.repoUrl),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Estado:',
                    appState.isRepositoryCloned ? 'Clonado' : 'No clonado',
                  ),
                  if (appState.isRepositoryCloned) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Rama actual:', _currentBranch),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Acciones de Git
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_download, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Acciones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading || !_hasCredentials ? null : _cloneRepository,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Clonar Repositorio'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || !appState.isRepositoryCloned ? null : _pullRepository,
                      icon: const Icon(Icons.sync),
                      label: const Text('Actualizar (Git Pull)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || !appState.isRepositoryCloned ? null : _changeBranch,
                      icon: const Icon(Icons.account_tree),
                      label: const Text('Cambiar de Rama'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logs
          if (_logs.isNotEmpty) ...[
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Logs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.clear_all),
                          tooltip: 'Limpiar logs',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    height: 300,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.grey[900],
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.grey[300]!;

                        if (log.contains('ERROR') || log.contains('❌')) {
                          textColor = Colors.red[300]!;
                        } else if (log.contains('✓') || log.contains('exitoso')) {
                          textColor = Colors.green[300]!;
                        }

                        return SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
