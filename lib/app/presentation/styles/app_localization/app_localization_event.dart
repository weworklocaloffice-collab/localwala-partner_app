part of 'app_localization_bloc.dart';

abstract class AppLocalizationEvent {
  const AppLocalizationEvent();
}

class AppLocalizationInitialEvent extends AppLocalizationEvent {
  const AppLocalizationInitialEvent();
}

class AppLocalizationChangeEvent extends AppLocalizationEvent {
  final String locale;

  const AppLocalizationChangeEvent(this.locale);
}