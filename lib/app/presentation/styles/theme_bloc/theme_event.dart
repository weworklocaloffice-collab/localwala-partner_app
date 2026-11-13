part of 'theme_bloc.dart';

abstract class ThemeEvent {
  const ThemeEvent();
}

class ThemeInitialEvent extends ThemeEvent {
  const ThemeInitialEvent();
}

class ThemeChangeEvent extends ThemeEvent {
  final AppTheme appTheme;

  const ThemeChangeEvent(this.appTheme);
}