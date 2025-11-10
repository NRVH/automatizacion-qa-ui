import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

/// Widget que muestra el estado de salud del workspace
class WorkspaceHealthWidget extends StatefulWidget {
  const WorkspaceHealthWidget({super.key});

  @override
  State<WorkspaceHealthWidget> createState() => _WorkspaceHealthWidgetState();
}

class _WorkspaceHealthWidgetState extends State<WorkspaceHealthWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    if (!appState.isRepositoryCloned) {
      return _buildNotClonedBanner(context);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: appState.scriptService.validateWorkspace(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingBanner(context);
        }

        if (snapshot.hasError) {
          return _buildErrorBanner(context, 'Error validando workspace', []);
        }

        final validation = snapshot.data!;
        final isReady = validation['isReady'] as bool;
        final errors = validation['errors'] as List<String>;
        final warnings = validation['warnings'] as List<String>;

        if (!isReady) {
          return _buildErrorBanner(
            context, 
            '${errors.length} ${errors.length == 1 ? 'error detectado' : 'errores detectados'}',
            errors,
          );
        }

        if (warnings.isNotEmpty) {
          return _buildWarningBanner(
            context, 
            '${warnings.length} ${warnings.length == 1 ? 'advertencia' : 'advertencias'}',
            warnings,
          );
        }

        // No mostrar nada cuando todo está bien (solo errores y warnings)
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNotClonedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          left: BorderSide(color: Colors.blue, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Repositorio no clonado. Ve a la pestaña Git para comenzar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border(
          left: BorderSide(color: Colors.grey, width: 4),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Validando workspace...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, String message, List<String> warnings) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border(
                left: BorderSide(color: Colors.orange, width: 4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && warnings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.orange)),
                    Expanded(child: Text(warning)),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message, List<String> errors) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border(
                left: BorderSide(color: Colors.red, width: 4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && errors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.red)),
                    Expanded(child: Text(error)),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}
