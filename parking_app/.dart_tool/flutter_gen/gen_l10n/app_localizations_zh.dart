// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '停车应用';

  @override
  String get welcomeMessage => '欢迎使用停车应用';

  @override
  String get login => '登录';

  @override
  String get logout => '登出';

  @override
  String get findParking => '查找停车位';

  @override
  String get availableSpots => '可用车位';

  @override
  String get parkingTime => '停车时间';

  @override
  String get startParking => '开始停车';

  @override
  String get endParking => '结束停车';

  @override
  String get payment => '支付';

  @override
  String get settings => '设置';

  @override
  String get profile => '个人资料';

  @override
  String get help => '帮助';

  @override
  String get language => '语言';

  @override
  String get email => '电子邮箱';

  @override
  String get password => '密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get or => '或者';

  @override
  String get createAccount => '还没有账户？注册';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get registerNow => '注册';

  @override
  String get requiredField => '此字段为必填项';

  @override
  String get invalidEmail => '请输入有效的电子邮箱地址';

  @override
  String get passwordTooShort => '密码至少需要6个字符';
}
