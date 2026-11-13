part of 'registration_bloc.dart';

/// Partner verticals supported by this app's registration forms.
enum RegistrationVertical {
  dairy(
    'dairy',
    'Dairy Partner',
    DairyPartnerEndpoints.registerSendOtp,
    DairyPartnerEndpoints.registerPartner,
    role: 'dairyPartner',
  ),
  dairyDriver(
    'dairy_driver',
    'Dairy Delivery Driver',
    DairyPartnerEndpoints.registerSendOtp,
    DairyPartnerEndpoints.registerDriver,
    role: 'dairyDriver',
  ),
  jhatka(
    'jhatka',
    'Jhatka Partner',
    JhatkaAuthEndpoints.registerSendOtp,
    JhatkaAuthEndpoints.registerPartner,
    role: 'jhatkaPartner',
  ),
  localServices(
    'local_services',
    'Local Services Partner',
    LocalServicesAuthEndpoints.registerSendOtp,
    LocalServicesAuthEndpoints.registerPartner,
    role: 'user',
  ),
  realEstate(
    'realestate',
    'Real Estate Partner',
    RealEstateAuthEndpoints.registerSendOtp,
    RealEstateAuthEndpoints.registerPartner,
    role: 'user',
  ),
  stores(
    'stores',
    'Stores Partner',
    StoresAuthEndpoints.registerSendOtp,
    StoresAuthEndpoints.registerPartner,
  );

  const RegistrationVertical(
    this.key,
    this.label,
    this.sendOtpEndpoint,
    this.registerEndpoint, {
    this.role,
  });

  final String key;
  final String label;
  final String sendOtpEndpoint;
  final String registerEndpoint;

  /// Stores assigns the applicant's role server-side and rejects this field.
  final String? role;

  /// Other verticals collect business details in their onboarding flows.
  bool get needsBusinessDetails => this == dairy || this == jhatka;

  bool get isDriver => this == dairyDriver;
}
