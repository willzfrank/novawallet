import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../queue/queue_processor.dart';

const String kLocaleKey = 'locale';

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(appStorageProvider);
    final code = storage.metaBox.get(kLocaleKey) as String? ?? 'en';
    return Locale(code);
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'en' ? 'yo' : 'en';
    state = Locale(next);
    await ref.read(appStorageProvider).metaBox.put(kLocaleKey, next);
  }
}
