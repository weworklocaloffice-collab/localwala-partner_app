part of 'app_localization_bloc.dart';

class AppLocalizationState {
  final String appLanguage;

  const AppLocalizationState({this.appLanguage = 'en'});

  AppLocalizationState copyWith({String? appLanguage}) =>
      AppLocalizationState(appLanguage: appLanguage ?? this.appLanguage);
}