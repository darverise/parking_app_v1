use actix_web::{App, HttpServer, middleware::Logger, web};
use crate::config::{
    logging::{init_logger, LogConfig},
    postgresql_database::{DatabaseConfig, PostgresDatabase},
};
use crate::middlewares::{
    cors_middleware::configure_cors,
    csrf_middleware::CsrfMiddleware,
    default_headers::DefaultHeadersMiddleware,
    error_handlers::ErrorHandlersMiddleware,
    identity_middleware::IdentityMiddleware,
    session_middleware::SessionMiddleware,
};
use crate::routes::route_config;

use std::io;

pub async fn start_server() -> std::io::Result<()> {
    // Load environment variables from .env file
    dotenv::dotenv().ok();

    // Initialize logging
    let log_config = LogConfig::from_env();
    let _guard = init_logger(log_config).map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;

    // Database connection setup
    let db_config = DatabaseConfig::from_env().map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;
    let db = web::Data::new(
        PostgresDatabase::connect(&db_config)
            .await
            .map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?,
    );

    // Configure and start the server
    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default()) // Request logging
            .wrap(configure_cors()) // CORS configuration
            .wrap(CsrfMiddleware) // CSRF protection
            .wrap(IdentityMiddleware::new()) // Identity management
            .wrap(SessionMiddleware::new()) // Session management
            .wrap(DefaultHeadersMiddleware) // Default response headers
            .wrap(ErrorHandlersMiddleware) // Error handling
            .app_data(db.clone()) // Share database connection pool
            .configure(route_config::init_routes) // Register routes
    })
    .workers(4) // Number of worker threads
    .bind("127.0.0.1:8080")?
    .run()
    .await
}