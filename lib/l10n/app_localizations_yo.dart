// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get sendMoneyTitle => 'Firanṣẹ Owo';

  @override
  String get recipient => 'Olùgbà';

  @override
  String get amount => 'Iye Owó';

  @override
  String get confirm => 'Jẹrìísí';

  @override
  String get confirmSend => 'Jẹrìísí Fíránṣẹ';

  @override
  String get pendingMessage => 'Nduro — yóò ránsẹ nígbà tí ìnẹ́tì padà';

  @override
  String get insufficientBalance => 'Owó kò tó';

  @override
  String get authRequired => 'Ìdánimọ̀ nílò láti tẹ̀síwájú';

  @override
  String get walletHome => 'Àpamọ́wọ́';

  @override
  String get balance => 'Iye Owó';

  @override
  String get recentTransactions => 'Àwọn Ìdúnàádúrà Àìpẹ́';

  @override
  String get noTransactions => 'Kò sí ìdúnàádúrà';

  @override
  String pendingActions(int count) {
    return '$count nduro';
  }

  @override
  String deadActions(int count) {
    return '$count gbígbé kùnà — tẹ láti tún gbìyànjú';
  }

  @override
  String get pullToRefresh => 'Fà láti mú ìmúdójúìwọ̀n';

  @override
  String get novaSave => 'NovaSave';

  @override
  String get myGoals => 'Àwọn Àfojúsùn Mi';

  @override
  String get noGoals => 'Kò sí àfojúsùn ìfipamọ́';

  @override
  String get createGoal => 'Ṣẹ̀dá Àfojúsùn';

  @override
  String get goalName => 'Orúkọ Àfojúsùn';

  @override
  String get targetAmount => 'Iye Owó Àfojúsùn';

  @override
  String get targetDate => 'Ọjọ́ Àfojúsùn';

  @override
  String get contribute => 'Ṣe Àfikún';

  @override
  String get progress => 'Ìlọsíwájú';

  @override
  String get saved => 'Ti Fipamọ́';

  @override
  String get ofLabel => 'nínú';

  @override
  String get goalCreated => 'Àfojúsùn jẹ́ ṣíṣẹ̀dá';

  @override
  String get contributed => 'Àfikún ti jẹ́ ìpèsè';

  @override
  String get retry => 'Tún Gbìyànjú';

  @override
  String get cancel => 'Fagilé';

  @override
  String get back => 'Padà';

  @override
  String get next => 'Tókàn';

  @override
  String get send => 'Firanṣẹ';

  @override
  String get success => 'Àṣeyọrí';

  @override
  String get error => 'Nǹkan àṣìṣe ṣẹlẹ̀';

  @override
  String get online => 'Orí Ẹ̀rọ';

  @override
  String get offline => 'Kò Sopọ̀';

  @override
  String get appName => 'NovaWallet';
}
