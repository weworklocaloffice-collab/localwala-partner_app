part of 'stores_settings_bloc.dart';

abstract class StoresSettingsEvent {
  const StoresSettingsEvent();
}

class StoresSettingsLoadEvent extends StoresSettingsEvent {
  const StoresSettingsLoadEvent();
}
