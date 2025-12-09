// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigModel _$ConfigModelFromJson(Map<String, dynamic> json) => ConfigModel(
  chromePath: json['chromePath'] as String,
  url: json['url'] as String,
  browser: BrowserConfig.fromJson(json['browser'] as Map<String, dynamic>),
  search: SearchConfig.fromJson(json['search'] as Map<String, dynamic>),
  passenger: PassengerConfig.fromJson(
    json['passenger'] as Map<String, dynamic>,
  ),
  payment: PaymentConfig.fromJson(json['payment'] as Map<String, dynamic>),
  login: json['login'] == null
      ? null
      : LoginConfig.fromJson(json['login'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConfigModelToJson(ConfigModel instance) =>
    <String, dynamic>{
      'chromePath': instance.chromePath,
      'url': instance.url,
      'browser': instance.browser,
      'search': instance.search,
      'passenger': instance.passenger,
      'payment': instance.payment,
      'login': instance.login,
    };

BrowserConfig _$BrowserConfigFromJson(
  Map<String, dynamic> json,
) => BrowserConfig(
  headless: json['headless'] as bool,
  viewport: ViewportConfig.fromJson(json['viewport'] as Map<String, dynamic>),
  recordVideo: json['recordVideo'] == null
      ? null
      : RecordVideoConfig.fromJson(json['recordVideo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BrowserConfigToJson(BrowserConfig instance) =>
    <String, dynamic>{
      'headless': instance.headless,
      'viewport': instance.viewport,
      'recordVideo': instance.recordVideo,
    };

ViewportConfig _$ViewportConfigFromJson(Map<String, dynamic> json) =>
    ViewportConfig(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$ViewportConfigToJson(ViewportConfig instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};

SearchConfig _$SearchConfigFromJson(Map<String, dynamic> json) => SearchConfig(
  origin: json['origin'] as String,
  destination: json['destination'] as String,
  date: json['date'] == null
      ? null
      : DateConfig.fromJson(json['date'] as Map<String, dynamic>),
  ventaAnticipada: json['ventaAnticipada'] as bool,
  service: (json['service'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SearchConfigToJson(SearchConfig instance) =>
    <String, dynamic>{
      'origin': instance.origin,
      'destination': instance.destination,
      'date': instance.date,
      'ventaAnticipada': instance.ventaAnticipada,
      'service': instance.service,
    };

DateConfig _$DateConfigFromJson(Map<String, dynamic> json) => DateConfig(
  type: json['type'] as String,
  days: (json['days'] as num).toInt(),
);

Map<String, dynamic> _$DateConfigToJson(DateConfig instance) =>
    <String, dynamic>{'type': instance.type, 'days': instance.days};

PassengerConfig _$PassengerConfigFromJson(Map<String, dynamic> json) =>
    PassengerConfig(
      name: json['name'] as String,
      lastnames: json['lastnames'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$PassengerConfigToJson(PassengerConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'lastnames': instance.lastnames,
      'email': instance.email,
      'phone': instance.phone,
    };

PaymentConfig _$PaymentConfigFromJson(Map<String, dynamic> json) =>
    PaymentConfig(
      cardNumber: json['cardNumber'] as String,
      holder: json['holder'] as String,
      expiry: json['expiry'] as String,
      cvv: json['cvv'] as String,
    );

Map<String, dynamic> _$PaymentConfigToJson(PaymentConfig instance) =>
    <String, dynamic>{
      'cardNumber': instance.cardNumber,
      'holder': instance.holder,
      'expiry': instance.expiry,
      'cvv': instance.cvv,
    };

LoginConfig _$LoginConfigFromJson(Map<String, dynamic> json) => LoginConfig(
  enabled: json['enabled'] as bool,
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginConfigToJson(LoginConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'email': instance.email,
      'password': instance.password,
    };

RecordVideoConfig _$RecordVideoConfigFromJson(Map<String, dynamic> json) =>
    RecordVideoConfig(
      enabled: json['enabled'] as bool,
      size: json['size'] == null
          ? null
          : VideoSizeConfig.fromJson(json['size'] as Map<String, dynamic>),
      convertToMp4: json['convertToMp4'] as bool? ?? true,
      deleteWebm: json['deleteWebm'] as bool? ?? false,
    );

Map<String, dynamic> _$RecordVideoConfigToJson(RecordVideoConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'size': instance.size,
      'convertToMp4': instance.convertToMp4,
      'deleteWebm': instance.deleteWebm,
    };

VideoSizeConfig _$VideoSizeConfigFromJson(Map<String, dynamic> json) =>
    VideoSizeConfig(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$VideoSizeConfigToJson(VideoSizeConfig instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};
