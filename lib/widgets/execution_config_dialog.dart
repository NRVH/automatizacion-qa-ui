import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/config_model.dart';

/// Diálogo para editar la configuración de una ejecución específica
class ExecutionConfigDialog extends StatefulWidget {
  final ConfigModel initialConfig;

  const ExecutionConfigDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<ExecutionConfigDialog> createState() => _ExecutionConfigDialogState();
}

class _ExecutionConfigDialogState extends State<ExecutionConfigDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configuración de Ejecución',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Form
            Expanded(
              child: FormBuilder(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Navegador
                      _buildSection(
                        title: 'Navegador',
                        icon: Icons.web,
                        children: [
                          FormBuilderTextField(
                            name: 'chromePath',
                            initialValue: widget.initialConfig.chromePath,
                            decoration: const InputDecoration(
                              labelText: 'Ruta del Navegador',
                              hintText: 'C:\\Program Files\\...\\chrome.exe',
                              border: OutlineInputBorder(),
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 12),
                          FormBuilderTextField(
                            name: 'url',
                            initialValue: widget.initialConfig.url,
                            decoration: const InputDecoration(
                              labelText: 'URL Base',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.url(),
                            ]),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Búsqueda
                      _buildSection(
                        title: 'Búsqueda de Boleto',
                        icon: Icons.search,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'origin',
                                  initialValue: widget.initialConfig.search.origin,
                                  decoration: const InputDecoration(
                                    labelText: 'Origen',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'destination',
                                  initialValue: widget.initialConfig.search.destination,
                                  decoration: const InputDecoration(
                                    labelText: 'Destino',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'days',
                                  initialValue: widget.initialConfig.search.date?.days.toString() ?? '5',
                                  decoration: const InputDecoration(
                                    labelText: 'Días de anticipación',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.numeric(),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderSwitch(
                                  name: 'ventaAnticipada',
                                  initialValue: widget.initialConfig.search.ventaAnticipada,
                                  title: const Text('Venta Anticipada'),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pasajero
                      _buildSection(
                        title: 'Datos del Pasajero',
                        icon: Icons.person,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'passengerName',
                                  initialValue: widget.initialConfig.passenger.name,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'passengerLastnames',
                                  initialValue: widget.initialConfig.passenger.lastnames,
                                  decoration: const InputDecoration(
                                    labelText: 'Apellidos',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'passengerEmail',
                                  initialValue: widget.initialConfig.passenger.email,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.email(),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'passengerPhone',
                                  initialValue: widget.initialConfig.passenger.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pago
                      _buildSection(
                        title: 'Datos de Pago',
                        icon: Icons.credit_card,
                        children: [
                          FormBuilderTextField(
                            name: 'cardNumber',
                            initialValue: widget.initialConfig.payment.cardNumber,
                            decoration: const InputDecoration(
                              labelText: 'Número de Tarjeta',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: FormBuilderTextField(
                                  name: 'cardHolder',
                                  initialValue: widget.initialConfig.payment.holder,
                                  decoration: const InputDecoration(
                                    labelText: 'Titular',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'cardExpiry',
                                  initialValue: widget.initialConfig.payment.expiry,
                                  decoration: const InputDecoration(
                                    labelText: 'Vencimiento',
                                    hintText: 'MM/YYYY',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'cardCvv',
                                  initialValue: widget.initialConfig.payment.cvv,
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
                      
                      const SizedBox(height: 20),
                      
                      // Login (opcional)
                      _buildSection(
                        title: 'Login (Opcional)',
                        icon: Icons.login,
                        children: [
                          FormBuilderSwitch(
                            name: 'loginEnabled',
                            initialValue: widget.initialConfig.login?.enabled ?? false,
                            title: const Text('Habilitar Login'),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          if (_formKey.currentState?.fields['loginEnabled']?.value == true) ...[
                            const SizedBox(height: 12),
                            FormBuilderTextField(
                              name: 'loginEmail',
                              initialValue: widget.initialConfig.login?.email ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Email de Login',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.email(),
                            ),
                            const SizedBox(height: 12),
                            FormBuilderTextField(
                              name: 'loginPassword',
                              initialValue: widget.initialConfig.login?.password ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Divider(height: 24),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saveConfig,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  void _saveConfig() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      // Crear nueva configuración con los valores del formulario
      final newConfig = ConfigModel(
        chromePath: formData['chromePath'] as String,
        url: formData['url'] as String,
        browser: widget.initialConfig.browser.copyWith(
          headless: false,
        ),
        search: SearchConfig(
          origin: formData['origin'] as String,
          destination: formData['destination'] as String,
          date: DateConfig(
            type: 'offset',
            days: int.tryParse(formData['days'] as String) ?? 5,
          ),
          ventaAnticipada: formData['ventaAnticipada'] as bool? ?? false,
        ),
        passenger: PassengerConfig(
          name: formData['passengerName'] as String,
          lastnames: formData['passengerLastnames'] as String,
          email: formData['passengerEmail'] as String,
          phone: formData['passengerPhone'] as String,
        ),
        payment: PaymentConfig(
          cardNumber: formData['cardNumber'] as String,
          holder: formData['cardHolder'] as String,
          expiry: formData['cardExpiry'] as String,
          cvv: formData['cardCvv'] as String,
        ),
        login: formData['loginEnabled'] == true
            ? LoginConfig(
                enabled: true,
                email: formData['loginEmail'] as String? ?? '',
                password: formData['loginPassword'] as String? ?? '',
              )
            : null,
      );
      
      Navigator.pop(context, newConfig);
    }
  }
}

// Extension para copyWith en BrowserConfig
extension BrowserConfigExtension on BrowserConfig {
  BrowserConfig copyWith({
    bool? headless,
    ViewportConfig? viewport,
  }) {
    return BrowserConfig(
      headless: headless ?? this.headless,
      viewport: viewport ?? this.viewport,
    );
  }
}
