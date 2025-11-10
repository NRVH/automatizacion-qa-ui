import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

@JsonSerializable()
class ConfigModel {
  final String chromePath;
  final String url;
  final BrowserConfig browser;
  final SearchConfig search;
  final PassengerConfig passenger;
  final PaymentConfig payment;
  final LoginConfig? login;

  ConfigModel({
    required this.chromePath,
    required this.url,
    required this.browser,
    required this.search,
    required this.passenger,
    required this.payment,
    this.login,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);

  factory ConfigModel.defaultConfig() {
    return ConfigModel(
      chromePath:
          r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
      url: 'https://estrellaroj adev-afa47.web.app/',
      browser: BrowserConfig(
        headless: false,
        viewport: ViewportConfig(width: 1600, height: 1200),
      ),
      search: SearchConfig(
        origin: 'Tapo',
        destination: 'Capu',
        date: DateConfig(type: 'offset', days: 5),
        ventaAnticipada: true,
      ),
      passenger: PassengerConfig(
        name: 'Nombre',
        lastnames: 'Apellidos',
        email: 'email@ejemplo.com',
        phone: '1234567890',
      ),
      payment: PaymentConfig(
        cardNumber: '1234567890123456',
        holder: 'NOMBRE EN TARJETA',
        expiry: '11/2030',
        cvv: '123',
      ),
      login: LoginConfig(
        enabled: false,
        email: 'email@ejemplo.com',
        password: 'password',
      ),
    );
  }

  /// Constructor de configuración vacía/por defecto
  factory ConfigModel.empty() => ConfigModel.defaultConfig();

  // Getters de conveniencia para mostrar información resumida
  String get navegador => chromePath.contains('Edge') ? 'Edge' : chromePath.contains('Chrome') ? 'Chrome' : 'Navegador';
  String get origen => search.origin;
  String get destino => search.destination;
  String get tipoBoleto => search.ventaAnticipada ? 'Venta Anticipada' : 'Normal';
}

@JsonSerializable()
class BrowserConfig {
  final bool headless;
  final ViewportConfig viewport;

  BrowserConfig({required this.headless, required this.viewport});

  factory BrowserConfig.fromJson(Map<String, dynamic> json) =>
      _$BrowserConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BrowserConfigToJson(this);
}

@JsonSerializable()
class ViewportConfig {
  final int width;
  final int height;

  ViewportConfig({required this.width, required this.height});

  factory ViewportConfig.fromJson(Map<String, dynamic> json) =>
      _$ViewportConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ViewportConfigToJson(this);
}

@JsonSerializable()
class SearchConfig {
  final String origin;
  final String destination;
  final DateConfig? date;
  final bool ventaAnticipada;

  SearchConfig({
    required this.origin,
    required this.destination,
    this.date,
    required this.ventaAnticipada,
  });

  factory SearchConfig.fromJson(Map<String, dynamic> json) =>
      _$SearchConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SearchConfigToJson(this);
}

@JsonSerializable()
class DateConfig {
  final String type;
  final int days;

  DateConfig({required this.type, required this.days});

  factory DateConfig.fromJson(Map<String, dynamic> json) =>
      _$DateConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DateConfigToJson(this);
}

@JsonSerializable()
class PassengerConfig {
  final String name;
  final String lastnames;
  final String email;
  final String phone;

  PassengerConfig({
    required this.name,
    required this.lastnames,
    required this.email,
    required this.phone,
  });

  factory PassengerConfig.fromJson(Map<String, dynamic> json) =>
      _$PassengerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PassengerConfigToJson(this);
}

@JsonSerializable()
class PaymentConfig {
  final String cardNumber;
  final String holder;
  final String expiry;
  final String cvv;

  PaymentConfig({
    required this.cardNumber,
    required this.holder,
    required this.expiry,
    required this.cvv,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) =>
      _$PaymentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentConfigToJson(this);
}

@JsonSerializable()
class LoginConfig {
  final bool enabled;
  final String email;
  final String password;

  LoginConfig({
    required this.enabled,
    required this.email,
    required this.password,
  });

  factory LoginConfig.fromJson(Map<String, dynamic> json) =>
      _$LoginConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LoginConfigToJson(this);
}
