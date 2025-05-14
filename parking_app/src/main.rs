use actix_cors::Cors;
use actix_web::{http::header, middleware, web, App, HttpResponse, HttpServer};
use dotenv::dotenv;
use std::{env, io::Result, time::Duration};
use tracing::{error, info};

use parking_app::config::{
    logging::{init_logger, LogConfig},
    postgresql_database::{DatabaseConfig, PostgresDatabase},
};
use parking_app::controllers::health;

struct ServerConfig {
    host: String,
    port: u16,
    workers: usize,
    keep_alive: u64,
    max_connections: usize,
    client_timeout: u64,
    client_shutdown: u64,
    cors_allow_origin: String,
    max_json_payload: usize,
}

impl ServerConfig {
    fn from_env() -> Self {
        Self {
            host: env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            port: env::var("PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .unwrap_or(8080),
            workers: env::var("SERVER_WORKERS")
                .unwrap_or_else(|_| "4".to_string())
                .parse()
                .unwrap_or(1),
            keep_alive: env::var("SERVER_KEEP_ALIVE")
                .unwrap_or_else(|_| "75".to_string())
                .parse()
                .unwrap_or(75),
            max_connections: env::var("SERVER_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "25000".to_string())
                .parse()
                .unwrap_or(25000),
            client_timeout: env::var("SERVER_CLIENT_TIMEOUT")
                .unwrap_or_else(|_| "60".to_string())
                .parse()
                .unwrap_or(60),
            client_shutdown: env::var("SERVER_CLIENT_SHUTDOWN")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            cors_allow_origin: env::var("CORS_ALLOW_ORIGIN").unwrap_or_else(|_| "*".to_string()),
            max_json_payload: env::var("MAX_REQUEST_BODY_SIZE")
                .unwrap_or_else(|_| "2097152".to_string())
                .parse()
                .unwrap_or(2097152),
        }
    }
}

#[actix_web::main]
async fn main() -> Result<()> {
    dotenv().ok();
    println!("DB_USERNAME: {:?}", std::env::var("DB_USERNAME"));
    let log_config = LogConfig::from_env();
    let _log_guard = init_logger(log_config).map_err(|e| {
        eprintln!("日志初始化失败: {}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "日志初始化失败")
    })?;
    info!("日志系统初始化成功");

    let server_config = ServerConfig::from_env();
    info!(
        "服务器配置: {}:{}, 工作线程: {}",
        server_config.host, server_config.port, server_config.workers
    );

    let db_config = DatabaseConfig::from_env().map_err(|e| {
        error!("数据库配置加载失败: {}", e);
        std::io::Error::new(std::io::ErrorKind::Other, format!("数据库配置错误: {}", e))
    })?;
    info!(
        "数据库配置已加载: {}:{}/{}",
        db_config.host, db_config.port, db_config.database_name
    );

    let db = PostgresDatabase::connect(&db_config).await.map_err(|e| {
        error!("数据库连接失败: {}", e);
        std::io::Error::new(std::io::ErrorKind::Other, format!("数据库连接失败: {}", e))
    })?;
    info!("数据库连接成功");

    let db_data = web::Data::new(db);

    info!(
        "正在启动 HTTP 服务器 http://{}:{}",
        server_config.host, server_config.port
    );

    let server = HttpServer::new(move || {
        let cors = {
            let mut cors = Cors::default()
                .allowed_methods(vec!["GET", "POST", "PUT", "DELETE", "OPTIONS"])
                .allowed_headers(vec![
                    header::AUTHORIZATION,
                    header::ACCEPT,
                    header::CONTENT_TYPE,
                ])
                .max_age(3600);

            if server_config.cors_allow_origin == "*" {
                cors = cors.send_wildcard();
            } else {
                cors = cors.allowed_origin(&server_config.cors_allow_origin);
            }
            cors
        };

        App::new()
            .app_data(db_data.clone())
            .app_data(web::JsonConfig::default().limit(server_config.max_json_payload))
            .wrap(middleware::Logger::default())
            .wrap(middleware::Compress::default())
            .wrap(middleware::NormalizePath::trim())
            .wrap(cors)
            .wrap(
                middleware::DefaultHeaders::new()
                    .add(("X-Version", env!("CARGO_PKG_VERSION")))
                    .add(("X-Server", "Parking App")),
            )
            .configure(health::config)
            .default_service(web::route().to(|| async {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Route not found",
                    "status": 404
                }))
            }))
    })
    .bind(format!("{}:{}", server_config.host, server_config.port))?
    .workers(server_config.workers)
    .keep_alive(Duration::from_secs(server_config.keep_alive))
    .client_request_timeout(Duration::from_secs(server_config.client_timeout))
    .client_disconnect_timeout(Duration::from_secs(server_config.client_shutdown))
    .max_connections(server_config.max_connections)
    .backlog((server_config.max_connections / 2).try_into().unwrap());

    info!("服务器启动成功，等待连接...");
    server.run().await
}
