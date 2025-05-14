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
    // 修复：使用 Writer<'_> 替换 &mut dyn std::fmt::Write
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
        }
    }
}

pub fn init_logger(config: LogConfig) -> io::Result<LoggerGuard> {
    let mut guards = Vec::new();
    let env_filter =
        EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(&config.log_level));

    let mut layers = Vec::new();

    // Console logger
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

    // File logger
    if config.enable_file_logging {
        // Create log directory if it doesn't exist
        std::fs::create_dir_all(&config.log_dir)?;

        // Application logs
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

        // Error logs - separate file for errors
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
        "Logging initialized: level={}, file_logging={}, console={}",
        config.log_level, config.enable_file_logging, config.enable_console
    );

    Ok(LoggerGuard { _guards: guards })
}

/// Create an additional logger for specific module or component
pub fn create_component_logger(
    config: &LogConfig,
    component_name: &str,
) -> io::Result<WorkerGuard> {
    if !config.enable_file_logging {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "File logging is disabled in configuration",
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

/// Set log level for specific module
pub fn set_module_log_level(module: &str, level: Level) {
    // This is a simplification as dynamically changing log levels requires more complex implementation
    // In a real application, you might use a more sophisticated approach with atomic/mutex-protected state
    let filter = format!("{}={}", module, level.as_str());
    if let Ok(filter) = EnvFilter::try_new(&filter) {
        tracing::subscriber::set_global_default(tracing_subscriber::registry().with(filter))
            .expect("Failed to set global default subscriber");
    }
}