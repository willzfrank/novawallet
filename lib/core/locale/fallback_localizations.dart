import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Material / Cupertino / Widgets have no Yoruba (`yo`) catalogs.
/// Claim support for all locales, load English Material strings as fallback
/// so AppLocalizations can still switch en ↔ yo without a red screen.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    if (GlobalMaterialLocalizations.delegate.isSupported(locale)) {
      return GlobalMaterialLocalizations.delegate.load(locale);
    }
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    if (GlobalCupertinoLocalizations.delegate.isSupported(locale)) {
      return GlobalCupertinoLocalizations.delegate.load(locale);
    }
    return GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) =>
      false;
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    if (GlobalWidgetsLocalizations.delegate.isSupported(locale)) {
      return GlobalWidgetsLocalizations.delegate.load(locale);
    }
    return GlobalWidgetsLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) =>
      false;
}
