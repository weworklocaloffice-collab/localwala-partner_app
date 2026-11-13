part of 'theme_bloc.dart';

class ThemeState {
  final AppTheme appTheme;

  const ThemeState({this.appTheme = AppTheme.light});

  bool get isDarkTheme => appTheme == AppTheme.dark;

  ThemeState copyWith({AppTheme? appTheme}) => ThemeState(appTheme: appTheme ?? this.appTheme);
}