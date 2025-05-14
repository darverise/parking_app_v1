# parking_app

Create a new Flutter project parking app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```bash
flutter --version
```

## Navigate to your Flutter project directory

```bash
cd parking_app
```

## Get dependencies

```bash
flutter pub get
```

## Run the app (this will build and launch on connected device/emulator)

```bash
flutter run
```

## For Android

```bash
flutter build apk --release
```

## For iOS

```bash
flutter build ios --release
```

## iOS Simulator

> Note: `xcrun` is a command-line tool in macOS that runs or locates development tools within the Xcode developer directory.
> `simctl` is a subcommand of xcrun for controlling the iOS Simulator programmatically.

```bash
# List all available iOS simulators
xcrun simctl list devices

# Launch a specific iOS simulator
open -a Simulator

# Or launch a specific device
xcrun simctl boot "iPhone 15 Pro" # Replace with your simulator name

# Run Flutter app in the launched simulator
flutter run
```

## Android Emulator

```bash
# List available Android emulators
flutter emulators

# Launch a specific Android emulator
flutter emulators --launch <emulator_id>

# Alternative way to launch using Android tools
cd ~/Library/Android/sdk/emulator
./emulator -avd <emulator_name>

# Run Flutter app in the launched emulator
flutter run
```

## Other

```bash
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
cd ios
pod install --repo-update
flutter run -d ios
flutter run -d android

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

## DART

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.login);

Dart 的命名规则与约定：

Dart 并没有强制要求文件名必须与主类名相同
文件名通常使用 snake_case（小写字母加下划线），如 response.dart
类名通常使用 UpperCamelCase（首字母大写驼峰式），如 ApiResponse


Flutter/Dart 的常见实践：

虽然没有强制规定，但通常一个 Dart 文件中定义的主要类名与文件名相对应是一个很好的实践
例如，如果主类是 ApiResponse，文件名最好是 api_response.dart
但在许多 Flutter 项目中，确实存在文件名与主类名不完全对应的情况
```

## RUST

``` rust
我已经创建了一个完整的 .env 文件，它包含了所有原始文件中的配置项，并补充了其他可能需要的设置。这个配置文件分为几个主要部分：
服务器设置

HOST：HTTP 服务器绑定的 IP 地址
PORT：HTTP 服务器监听端口

数据库设置

DB_HOST：PostgreSQL 数据库主机名
DB_PORT：PostgreSQL 数据库端口
DB_INITIAL_DATABASE：数据库名称
DB_USERNAME：数据库用户名
DB_PASSWORD：数据库密码
DB_MAX_CONNECTIONS：连接池最大连接数
DB_CONNECTION_TIMEOUT：连接超时（秒）
DB_IDLE_TIMEOUT：空闲连接超时（秒）
DB_POOL_TIMEOUT：获取连接池连接的超时时间（秒）
DB_CONNECTION_POOL_SIZE：连接池初始大小

JWT 设置

JWT_SECRET：用于签名 JWT 的密钥

日志设置

RUST_LOG：Rust 日志级别
LOG_LEVEL：应用日志级别
LOG_DIR：日志文件目录
APP_NAME：应用名称（用于日志文件名）
ENABLE_FILE_LOGGING：是否启用文件日志
ENABLE_CONSOLE_LOGGING：是否启用控制台日志

应用特定设置

API_TIMEOUT：API 请求超时时间（秒）
ENABLE_SWAGGER：是否启用 Swagger 文档
CORS_ALLOW_ORIGIN：CORS 允许的源
MAX_REQUEST_BODY_SIZE：请求体最大大小（字节）

速率限制设置

RATE_LIMIT_REQUESTS：单位时间内允许的最大请求数
RATE_LIMIT_DURATION：速率限制时间段（秒）

安全设置

SECURE_COOKIES：是否使用安全 Cookie（生产环境应设为 true）
HASH_COST：bcrypt 哈希成本因子
PASSWORD_MIN_LENGTH：密码最小长度

开发/调试设置

DEBUG_MODE：是否启用调试模式（生产环境应设为 false）
PRINT_DB_QUERIES：是否打印数据库查询
```
