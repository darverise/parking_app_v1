//! # Parking Application
//!
//! This is the core backend service for the parking management application.
//! The application follows a layered architecture with:
//!
//! - Controllers: Handle HTTP requests and responses
//! - Services: Implement business logic
//! - Repositories: Handle data access and persistence
//! - Models: Define data structures
//! - Middlewares: Provide request processing capabilities
//! - Configuration: Application settings and infrastructure setup

// Public modules
pub mod config;
pub mod controllers;
pub mod middlewares;
pub mod models;
pub mod repositories;
pub mod routes;
pub mod services;

// Re-exports of commonly used items
pub use config::app_config::AppConfig;
pub use config::postgresql_database::PostgresDatabase;
pub use controllers::api_error::ApiError;

/// Initialize the application
///
/// This function should be called once at application startup
/// to perform any necessary initialization of the various components.
pub async fn init() -> Result<(), String> {
    // Initialize tracing/logging first for proper diagnostics
    tracing::info!("Initializing application");
    
    // Initialize services
    services::init();
    
    // Other initialization as needed
    tracing::info!("Application initialization complete");
    
    Ok(())
}

/// Graceful shutdown handling
///
/// This function should be called when shutting down the application
/// to ensure resources are properly cleaned up.
pub async fn shutdown() -> Result<(), String> {
    tracing::info!("Shutting down application");
    
    // Perform cleanup operations here
    
    tracing::info!("Application shutdown complete");
    Ok(())
}
