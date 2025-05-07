// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'パーキングアプリ';

  @override
  String get welcomeMessage => 'パーキングアプリへようこそ';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get findParking => '駐車場を探す';

  @override
  String get availableSpots => '利用可能なスポット';

  @override
  String get parkingTime => '駐車時間';

  @override
  String get startParking => '駐車開始';

  @override
  String get endParking => '駐車終了';

  @override
  String get payment => '支払い';

  @override
  String get settings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get help => 'ヘルプ';

  @override
  String get language => '言語';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get forgotPassword => 'パスワードをお忘れの方はこちら';

  @override
  String get or => 'または';

  @override
  String get createAccount => 'アカウントをお持ちでないですか？新規登録';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordHint => 'パスワードを入力';

  @override
  String get registerNow => '新規登録';

  @override
  String get requiredField => 'この項目は必須です';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get passwordTooShort => 'パスワードは6文字以上で入力してください';
}
