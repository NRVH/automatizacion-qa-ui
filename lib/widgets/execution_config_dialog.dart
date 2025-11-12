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

  // Variables de estado para controlar visibilidad de opciones
  late bool _recordVideoEnabled;
  late bool _useCustomVideoSize;

  @override
  void initState() {
    super.initState();
    _recordVideoEnabled = widget.initialConfig.browser.recordVideo?.enabled ?? false;
    _useCustomVideoSize = widget.initialConfig.browser.recordVideo?.size != null;
  }

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
                      
                      // 1. Grabación de Video
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            leading: Icon(Icons.videocam, color: Colors.red[700]),
                            title: const Text(
                              'Grabación de Video',
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
                              FormBuilderSwitch(
                                name: 'recordVideoEnabled',
                                initialValue: widget.initialConfig.browser.recordVideo?.enabled ?? false,
                                title: const Text('Habilitar grabación'),
                                subtitle: const Text('Graba toda la ejecución del script'),
                                onChanged: (value) => setState(() => _recordVideoEnabled = value ?? false),
                              ),
                              if (_recordVideoEnabled) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'El video se guardará en la carpeta de evidencias',
                                          style: TextStyle(fontSize: 11, color: Colors.orange[900]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderSwitch(
                                  name: 'convertToMp4',
                                  initialValue: widget.initialConfig.browser.recordVideo?.convertToMp4 ?? true,
                                  title: const Text('Convertir a MP4'),
                                  subtitle: const Text('Compatible con Windows (requiere FFmpeg)'),
                                ),
                                const SizedBox(height: 8),
                                FormBuilderSwitch(
                                  name: 'deleteWebm',
                                  initialValue: widget.initialConfig.browser.recordVideo?.deleteWebm ?? false,
                                  title: const Text('Eliminar WebM original'),
                                  subtitle: const Text('Borrar WebM después de convertir'),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderSwitch(
                                  name: 'useCustomVideoSize',
                                  initialValue: widget.initialConfig.browser.recordVideo?.size != null,
                                  title: const Text('Resolución personalizada'),
                                  subtitle: const Text('Diferente al viewport del navegador'),
                                  onChanged: (value) => setState(() => _useCustomVideoSize = value ?? false),
                                ),
                                if (_useCustomVideoSize) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'videoWidth',
                                          initialValue: (widget.initialConfig.browser.recordVideo?.size?.width ??
                                                  widget.initialConfig.browser.viewport.width)
                                              .toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Ancho',
                                            border: OutlineInputBorder(),
                                            suffixText: 'px',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'videoHeight',
                                          initialValue: (widget.initialConfig.browser.recordVideo?.size?.height ??
                                                  widget.initialConfig.browser.viewport.height)
                                              .toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Alto',
                                            border: OutlineInputBorder(),
                                            suffixText: 'px',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.red[700], size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Advertencias',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '• Videos: 50-200 MB por ejecución\n'
                                        '• Puede reducir rendimiento\n'
                                        '• Navegador se cierra al terminar\n'
                                        '• Requiere FFmpeg para MP4',
                                        style: TextStyle(fontSize: 10, color: Colors.red[900], height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        isExpanded: _expandedPanel == 1,
                      ),
                      
                      // 2. Búsqueda
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
                        isExpanded: _expandedPanel == 2,
                      ),
                      
                      // 3. Pasajero
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
                                _expandedPanel = _expandedPanel == 3 ? -1 : 3;
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
                        isExpanded: _expandedPanel == 3,
                      ),

                      // 4. Pago
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
                                _expandedPanel = _expandedPanel == 4 ? -1 : 4;
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
                        isExpanded: _expandedPanel == 4,
                      ),

                      // 5. Login(opcional)
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
                                _expandedPanel = _expandedPanel == 5 ? -1 : 5;
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
                        isExpanded: _expandedPanel == 5,
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
        browser: BrowserConfig(
          headless: false,
          viewport: widget.initialConfig.browser.viewport,
          recordVideo: (formData['recordVideoEnabled'] as bool?) ?? false
              ? RecordVideoConfig(
                  enabled: true,
                  size: (formData['useCustomVideoSize'] as bool?) ?? false
                      ? VideoSizeConfig(
                          width: int.tryParse(formData['videoWidth']?.toString() ?? '1920') ?? 1920,
                          height: int.tryParse(formData['videoHeight']?.toString() ?? '1080') ?? 1080,
                        )
                      : null,
                  convertToMp4: (formData['convertToMp4'] as bool?) ?? true,
                  deleteWebm: (formData['deleteWebm'] as bool?) ?? false,
                )
              : null,
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
