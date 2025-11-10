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
  
  // Control de secciones expandidas (solo Navegador abierto por defecto)
  int _expandedPanel = 0; // 0 = Navegador

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
                  child: ExpansionPanelList(
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        // Alternar: si el panel clickeado es el actual, colapsarlo
                        // Si es otro panel, expandirlo
                        _expandedPanel = _expandedPanel == index ? -1 : index;
                      });
                    },
                    children: [
                      // 0. Navegador (abierto por defecto)
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.web, color: Theme.of(context).colorScheme.primary),
                            title: const Text(
                              'Navegador',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedPanel = _expandedPanel == 0 ? -1 : 0;
                              });
                            },
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
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
                        ),
                        isExpanded: _expandedPanel == 0,
                      ),
                      
                      // 1. Búsqueda
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                            title: const Text(
                              'Búsqueda de Boleto',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedPanel = _expandedPanel == 1 ? -1 : 1;
                              });
                            },
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
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
                        ),
                        isExpanded: _expandedPanel == 1,
                      ),
                      
                      // 2. Pasajero
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                            title: const Text(
                              'Datos del Pasajero',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedPanel = _expandedPanel == 2 ? -1 : 2;
                              });
                            },
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
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
                        ),
                        isExpanded: _expandedPanel == 2,
                      ),
                      
                      // 3. Pago
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
                            title: const Text(
                              'Datos de Pago',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedPanel = _expandedPanel == 3 ? -1 : 3;
                              });
                            },
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
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
                        ),
                        isExpanded: _expandedPanel == 3,
                      ),
                      
                      // 4. Login (opcional)
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                            title: const Text(
                              'Login (Opcional)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedPanel = _expandedPanel == 4 ? -1 : 4;
                              });
                            },
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
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
                        ),
                        isExpanded: _expandedPanel == 4,
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
