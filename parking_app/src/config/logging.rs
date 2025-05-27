use chrono::Local;
use std::{env, io, path::Path};
use tracing::{info, Level};
use tracing_appender::{
    non_blocking::WorkerGuard,
    rolling::{RollingFileAppender, Rotation},
};
use tracing_subscriber::{
    fmt::{format::FmtSpan, format::Writer, time::FormatTime},
    layer::SubscriberExt,
    util::SubscriberInitExt,
    EnvFilter, Layer,
};

pub struct LocalTimer;

impl FormatTime for LocalTimer {
    // 時刻フォーマッターの実装：Writer<'_>を使用
    fn format_time(&self, w: &mut Writer<'_>) -> std::fmt::Result {
        write!(w, "{}", Local::now().format("%Y-%m-%d %H:%M:%S%.3f"))
    }
}

pub struct LoggerGuard {
    _guards: Vec<WorkerGuard>,
}

pub struct LogConfig {
    pub log_level: String,
    pub log_dir: String,
    pub app_name: String,
    pub enable_file_logging: bool,
    pub enable_console: bool,
    pub enable_sql_logging: bool,
    pub format_sql: bool,
}

impl LogConfig {
    pub fn from_env() -> Self {
        Self {
            log_level: env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string()),
            log_dir: env::var("LOG_DIR").unwrap_or_else(|_| "logs".to_string()),
            app_name: env::var("APP_NAME").unwrap_or_else(|_| "parking_app".to_string()),
            enable_file_logging: env::var("ENABLE_FILE_LOGGING")
                .map(|v| v.to_lowercase() == "true")
                .unwrap_or(true),
            enable_console: env::var("ENABLE_CONSOLE_LOGGING")
                .map(|v| v.to_lowercase() == "true")
                .unwrap_or(true),
            enable_sql_logging: env::var("ENABLE_SQL_LOGGING")
                .map(|v| v.to_lowercase() == "true")
                .unwrap_or(true),
            format_sql: env::var("FORMAT_SQL")
                .map(|v| v.to_lowercase() == "true")
                .unwrap_or(true),
        }
    }
}

pub fn init_logger(config: LogConfig) -> io::Result<LoggerGuard> {
    let mut guards = Vec::new();
    let env_filter =
        EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(&config.log_level));

    let mut layers = Vec::new();

    // コンソールロガー
    if config.enable_console {
        let (console_writer, console_guard) = tracing_appender::non_blocking(io::stdout());
        guards.push(console_guard);

        let console_layer = tracing_subscriber::fmt::layer()
            .with_writer(console_writer)
            .with_timer(LocalTimer)
            .with_ansi(true)
            .with_thread_ids(true)
            .with_thread_names(true)
            .with_target(true)
            .with_span_events(FmtSpan::CLOSE)
            .boxed();

        layers.push(console_layer);
    }

    // ファイルロガー
    if config.enable_file_logging {
        // ログディレクトリの作成
        std::fs::create_dir_all(&config.log_dir)?;

        // アプリケーションログ
        let app_file = RollingFileAppender::new(
            Rotation::DAILY,
            &config.log_dir,
            format!("{}.log", config.app_name),
        );
        let (app_writer, app_guard) = tracing_appender::non_blocking(app_file);
        guards.push(app_guard);

        let app_layer = tracing_subscriber::fmt::layer()
            .with_writer(app_writer)
            .with_timer(LocalTimer)
            .with_ansi(false)
            .with_thread_ids(true)
            .with_thread_names(true)
            .with_target(true)
            .boxed();

        layers.push(app_layer);

        // エラーログ - エラー用の別ファイル
        let error_file = RollingFileAppender::new(
            Rotation::DAILY,
            &config.log_dir,
            format!("{}_error.log", config.app_name),
        );
        let (error_writer, error_guard) = tracing_appender::non_blocking(error_file);
        guards.push(error_guard);

        let error_layer = tracing_subscriber::fmt::layer()
            .with_writer(error_writer)
            .with_timer(LocalTimer)
            .with_ansi(false)
            .with_thread_ids(true)
            .with_thread_names(true)
            .with_target(true)
            .with_filter(tracing_subscriber::filter::LevelFilter::ERROR)
            .boxed();

        layers.push(error_layer);
    }

    tracing_subscriber::registry()
        .with(env_filter)
        .with(layers)
        .init();

    info!(
        "ログシステムが正常に初期化されました: レベル={}, ファイル出力={}, コンソール出力={}",
        config.log_level, config.enable_file_logging, config.enable_console
    );

    Ok(LoggerGuard { _guards: guards })
}

/// 特定のモジュールやコンポーネント用の専用ログ作成
pub fn create_component_logger(
    config: &LogConfig,
    component_name: &str,
) -> io::Result<WorkerGuard> {
    if !config.enable_file_logging {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "設定でファイルログ出力が無効になっています",
        ));
    }

    let log_path =
        Path::new(&config.log_dir).join(format!("{}_{}.log", config.app_name, component_name));
    if let Some(parent) = log_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let appender = RollingFileAppender::new(
        Rotation::DAILY,
        &config.log_dir,
        format!("{}_{}.log", config.app_name, component_name),
    );

    let (writer, guard) = tracing_appender::non_blocking(appender);

    let component_layer = tracing_subscriber::fmt::layer()
        .with_writer(writer)
        .with_timer(LocalTimer)
        .with_ansi(false)
        .with_thread_ids(true)
        .with_thread_names(true)
        .with_target(true)
        .with_filter(EnvFilter::new(format!(
            "{}={}",
            component_name, config.log_level
        )));

    tracing_subscriber::registry().with(component_layer).init();

    Ok(guard)
}

/// 特定モジュールのログレベル設定
pub fn set_module_log_level(module: &str, level: Level) {
    // 動的なログレベル変更には、より複雑な実装が必要
    // 実際のアプリケーションでは、atomic/mutexで保護された状態を使用することを推奨
    let filter = format!("{}={}", module, level.as_str());
    if let Ok(filter) = EnvFilter::try_new(&filter) {
        tracing::subscriber::set_global_default(tracing_subscriber::registry().with(filter))
            .expect("グローバルデフォルト購読者の設定に失敗しました");
    }
}

/// SQLログ出力用のパラメータ値
#[derive(Debug, Clone)]
pub enum SqlParam {
    String(String),
    Integer(i64),
    Float(f64),
    Boolean(bool),
    Null,
}

impl std::fmt::Display for SqlParam {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SqlParam::String(s) => write!(f, "'{}'", s.replace('\'', "''")),
            SqlParam::Integer(i) => write!(f, "{}", i),
            SqlParam::Float(fl) => write!(f, "{}", fl),
            SqlParam::Boolean(b) => write!(f, "{}", b),
            SqlParam::Null => write!(f, "NULL"),
        }
    }
}

/// SQLクエリをパラメータ置換でフォーマット
pub fn format_sql_query(query: &str, params: &[SqlParam]) -> String {
    let mut formatted_query = query.to_string();

    // PostgreSQLプレースホルダー（$1, $2等）を置換
    // 競合を避けるため、プレースホルダー番号の降順でソート（$10を$1より先に処理）
    for index in (0..params.len()).rev() {
        let placeholder = format!("${}", index + 1);
        if let Some(param) = params.get(index) {
            formatted_query = formatted_query.replace(&placeholder, &param.to_string());
        }
    }

    if formatted_query.contains("SELECT") || formatted_query.contains("select") {
        format_select_query(&formatted_query)
    } else if formatted_query.contains("INSERT") || formatted_query.contains("insert") {
        format_insert_query(&formatted_query)
    } else if formatted_query.contains("UPDATE") || formatted_query.contains("update") {
        format_update_query(&formatted_query)
    } else if formatted_query.contains("DELETE") || formatted_query.contains("delete") {
        format_delete_query(&formatted_query)
    } else {
        formatted_query
    }
}

/// SELECT文を適切なインデントでフォーマット
fn format_select_query(query: &str) -> String {
    let mut formatted = String::new();
    let parts: Vec<&str> = query.split_whitespace().collect();
    let mut i = 0;

    while i < parts.len() {
        let word = parts[i].to_uppercase();
        match word.as_str() {
            "SELECT" => {
                formatted.push_str("SELECT ");
                i += 1;
                // フィールドを追加
                while i < parts.len()
                    && !["FROM", "WHERE", "GROUP", "HAVING", "ORDER", "LIMIT"]
                        .contains(&parts[i].to_uppercase().as_str())
                {
                    if parts[i].ends_with(',') {
                        formatted.push_str(&format!("{}\n       ", parts[i]));
                    } else {
                        formatted.push_str(&format!("{} ", parts[i]));
                    }
                    i += 1;
                }
            }
            "FROM" => {
                formatted.push_str("\nFROM ");
                i += 1;
                while i < parts.len()
                    && !["WHERE", "GROUP", "HAVING", "ORDER", "LIMIT"]
                        .contains(&parts[i].to_uppercase().as_str())
                {
                    formatted.push_str(&format!("{} ", parts[i]));
                    i += 1;
                }
            }
            "WHERE" => {
                formatted.push_str("\nWHERE ");
                i += 1;
                while i < parts.len()
                    && !["GROUP", "HAVING", "ORDER", "LIMIT"]
                        .contains(&parts[i].to_uppercase().as_str())
                {
                    formatted.push_str(&format!("{} ", parts[i]));
                    i += 1;
                }
            }
            "GROUP" => {
                if i + 1 < parts.len() && parts[i + 1].to_uppercase() == "BY" {
                    formatted.push_str("\nGROUP BY ");
                    i += 2;
                    while i < parts.len()
                        && !["HAVING", "ORDER", "LIMIT"].contains(&parts[i].to_uppercase().as_str())
                    {
                        formatted.push_str(&format!("{} ", parts[i]));
                        i += 1;
                    }
                } else {
                    formatted.push_str(&format!("{} ", parts[i]));
                    i += 1;
                }
            }
            "ORDER" => {
                if i + 1 < parts.len() && parts[i + 1].to_uppercase() == "BY" {
                    formatted.push_str("\nORDER BY ");
                    i += 2;
                    while i < parts.len() && !["LIMIT"].contains(&parts[i].to_uppercase().as_str())
                    {
                        formatted.push_str(&format!("{} ", parts[i]));
                        i += 1;
                    }
                } else {
                    formatted.push_str(&format!("{} ", parts[i]));
                    i += 1;
                }
            }
            "LIMIT" => {
                formatted.push_str("\nLIMIT ");
                i += 1;
                while i < parts.len() {
                    formatted.push_str(&format!("{} ", parts[i]));
                    i += 1;
                }
            }
            _ => {
                formatted.push_str(&format!("{} ", parts[i]));
                i += 1;
            }
        }
    }

    formatted.trim().to_string()
}

/// INSERT文をフォーマット
fn format_insert_query(query: &str) -> String {
    query
        .replace(" VALUES ", "\nVALUES ")
        .replace(" INTO ", "\nINTO ")
}

/// UPDATE文をフォーマット
fn format_update_query(query: &str) -> String {
    query
        .replace(" SET ", "\nSET ")
        .replace(" WHERE ", "\nWHERE ")
}

/// DELETE文をフォーマット
fn format_delete_query(query: &str) -> String {
    query
        .replace(" FROM ", "\nFROM ")
        .replace(" WHERE ", "\nWHERE ")
}

/// SQLクエリとパラメータをログ出力
pub fn log_sql_query(query: &str, params: &[SqlParam], execution_time_ms: Option<u128>) {
    let formatted_sql = format_sql_query(query, params);

    match execution_time_ms {
        Some(time) => {
            info!(
                target: "sql",
                execution_time_ms = time,
                "SQLクエリが実行されました（実行時間: {}ms）:\n{}",
                time,
                formatted_sql
            );
        }
        None => {
            info!(
                target: "sql",
                "SQLクエリ:\n{}",
                formatted_sql
            );
        }
    }
}

/// SQLクエリエラーをログ出力
pub fn log_sql_error(query: &str, params: &[SqlParam], error: &str) {
    let formatted_sql = format_sql_query(query, params);

    tracing::error!(
        target: "sql",
        error = error,
        "SQLクエリの実行でエラーが発生しました:\nエラー: {}\nクエリ:\n{}",
        error,
        formatted_sql
    );
}

/// パラメータ置換を使用したSQLログ出力の簡易マクロ
#[macro_export]
macro_rules! log_sql {
    ($query:expr, $params:expr) => {
        $crate::config::logging::log_sql_query($query, $params, None)
    };
    ($query:expr, $params:expr, $execution_time:expr) => {
        $crate::config::logging::log_sql_query($query, $params, Some($execution_time))
    };
}

/// SQLエラーログ出力マクロ
#[macro_export]
macro_rules! log_sql_error {
    ($query:expr, $params:expr, $error:expr) => {
        $crate::config::logging::log_sql_error($query, $params, $error)
    };
}
