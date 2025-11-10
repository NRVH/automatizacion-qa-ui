import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../providers/app_state_provider.dart';
import '../models/config_model.dart';

class ConfigEditorScreen extends StatefulWidget {
  const ConfigEditorScreen({super.key});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  
  // Control de expansión de secciones
  bool _navegadorExpanded = true;
  bool _busquedaExpanded = false;
  bool _pasajeroExpanded = false;
  bool _pagoExpanded = false;
  bool _loginExpanded = false;

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSaving = true);

      final formData = _formKey.currentState!.value;
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      try {
        final newConfig = ConfigModel(
          chromePath: (formData['chromePath'] as String?) ?? '',
          url: (formData['url'] as String?) ?? '',
          browser: BrowserConfig(
            headless: (formData['headless'] as bool?) ?? false,
            viewport: ViewportConfig(
              width: int.tryParse(formData['viewportWidth']?.toString() ?? '1920') ?? 1920,
              height: int.tryParse(formData['viewportHeight']?.toString() ?? '1080') ?? 1080,
            ),
          ),
          search: SearchConfig(
            origin: (formData['origin'] as String?) ?? '',
            destination: (formData['destination'] as String?) ?? '',
            date: DateConfig(
              type: 'offset',
              days: int.tryParse(formData['dateDays']?.toString() ?? '5') ?? 5,
            ),
            ventaAnticipada: (formData['ventaAnticipada'] as bool?) ?? false,
          ),
          passenger: PassengerConfig(
            name: (formData['passengerName'] as String?) ?? '',
            lastnames: (formData['passengerLastnames'] as String?) ?? '',
            email: (formData['passengerEmail'] as String?) ?? '',
            phone: (formData['passengerPhone'] as String?) ?? '',
          ),
          payment: PaymentConfig(
            cardNumber: (formData['cardNumber'] as String?) ?? '',
            holder: (formData['cardHolder'] as String?) ?? '',
            expiry: (formData['cardExpiry'] as String?) ?? '',
            cvv: (formData['cardCvv'] as String?) ?? '',
          ),
          login: LoginConfig(
            enabled: (formData['loginEnabled'] as bool?) ?? false,
            email: (formData['loginEmail'] as String?) ?? '',
            password: (formData['loginPassword'] as String?) ?? '',
          ),
        );

        await appState.updateConfig(newConfig);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error guardando configuración: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final config = appState.config;

    if (config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Botón guardar fijo en la parte superior
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            label: Text(
              _isSaving ? 'Guardando...' : 'Guardar Configuración',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        // Formulario scrolleable
        Expanded(
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edita los parámetros de configuración para la compra de boletos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Navegador
                  _buildExpandableSection(
                    context,
                    title: 'Navegador',
                    icon: Icons.web,
                    isExpanded: _navegadorExpanded,
                    onToggle: (value) => setState(() => _navegadorExpanded = value),
                    children: [
                FormBuilderTextField(
                  name: 'chromePath',
                  initialValue: config.chromePath,
                  decoration: const InputDecoration(
                    labelText: 'Ruta del navegador',
                    helperText: 'Ruta completa al navegador (Edge, Chrome)',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'url',
                  initialValue: config.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de la aplicación',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.url(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderSwitch(
                  name: 'headless',
                  initialValue: config.browser.headless,
                  title: const Text('Modo headless (sin interfaz)'),
                  subtitle: const Text('Ejecutar el navegador en segundo plano'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'viewportWidth',
                        initialValue: config.browser.viewport.width.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Ancho de ventana',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'viewportHeight',
                        initialValue: config.browser.viewport.height.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Alto de ventana',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Búsqueda
            _buildExpandableSection(
              context,
              title: 'Búsqueda de Viaje',
              icon: Icons.search,
              isExpanded: _busquedaExpanded,
              onToggle: (value) => setState(() => _busquedaExpanded = value),
              children: [
                FormBuilderTextField(
                  name: 'origin',
                  initialValue: config.search.origin,
                  decoration: const InputDecoration(
                    labelText: 'Origen',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'destination',
                  initialValue: config.search.destination,
                  decoration: const InputDecoration(
                    labelText: 'Destino',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'dateDays',
                  initialValue: config.search.date?.days.toString() ?? '5',
                  decoration: const InputDecoration(
                    labelText: 'Días desde hoy',
                    helperText: 'Fecha de viaje (días desde hoy)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderSwitch(
                  name: 'ventaAnticipada',
                  initialValue: config.search.ventaAnticipada,
                  title: const Text('Venta anticipada'),
                  subtitle: const Text('Usar promoción de venta anticipada'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pasajero
            _buildExpandableSection(
              context,
              title: 'Datos del Pasajero',
              icon: Icons.person,
              isExpanded: _pasajeroExpanded,
              onToggle: (value) => setState(() => _pasajeroExpanded = value),
              children: [
                FormBuilderTextField(
                  name: 'passengerName',
                  initialValue: config.passenger.name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'passengerLastnames',
                  initialValue: config.passenger.lastnames,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'passengerEmail',
                  initialValue: config.passenger.email,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'passengerPhone',
                  initialValue: config.passenger.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: FormBuilderValidators.required(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pago
            _buildExpandableSection(
              context,
              title: 'Datos de Pago',
              icon: Icons.credit_card,
              isExpanded: _pagoExpanded,
              onToggle: (value) => setState(() => _pagoExpanded = value),
              children: [
                FormBuilderTextField(
                  name: 'cardNumber',
                  initialValue: config.payment.cardNumber,
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'cardHolder',
                  initialValue: config.payment.holder,
                  decoration: const InputDecoration(
                    labelText: 'Nombre en la tarjeta',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'cardExpiry',
                        initialValue: config.payment.expiry,
                        decoration: const InputDecoration(
                          labelText: 'Expiración (MM/AAAA)',
                          border: OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'cardCvv',
                        initialValue: config.payment.cvv,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Login
            _buildExpandableSection(
              context,
              title: 'Inicio de Sesión (Opcional)',
              icon: Icons.login,
              isExpanded: _loginExpanded,
              onToggle: (value) => setState(() => _loginExpanded = value),
              children: [
                FormBuilderSwitch(
                  name: 'loginEnabled',
                  initialValue: config.login?.enabled ?? false,
                  title: const Text('Habilitar inicio de sesión'),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'loginEmail',
                  initialValue: config.login?.email ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.email(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'loginPassword',
                  initialValue: config.login?.password ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onToggle,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
