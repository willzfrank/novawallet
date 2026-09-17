// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sendMoneyTitle => 'Send Money';

  @override
  String get recipient => 'Recipient';

  @override
  String get amount => 'Amount';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmSend => 'Confirm Send';

  @override
  String get pendingMessage => 'Pending — will send when back online';

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String get authRequired => 'Authentication required to proceed';

  @override
  String get walletHome => 'Wallet';

  @override
  String get balance => 'Balance';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String pendingActions(int count) {
    return '$count pending';
  }

  @override
  String deadActions(int count) {
    return '$count transfer(s) failed — tap to retry';
  }

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get novaSave => 'NovaSave';

  @override
  String get myGoals => 'My Goals';

  @override
  String get noGoals => 'No savings goals yet';

  @override
  String get createGoal => 'Create Goal';

  @override
  String get goalName => 'Goal Name';

  @override
  String get targetAmount => 'Target Amount';

  @override
  String get targetDate => 'Target Date';

  @override
  String get contribute => 'Contribute';

  @override
  String get progress => 'Progress';

  @override
  String get saved => 'Saved';

  @override
  String get ofLabel => 'of';

  @override
  String get goalCreated => 'Goal created successfully';

  @override
  String get contributed => 'Contribution queued';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get send => 'Send';

  @override
  String get success => 'Success';

  @override
  String get error => 'Something went wrong';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get appName => 'NovaWallet';
}
