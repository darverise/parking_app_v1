//! Repository layer for the parking application.
//!
//! This module contains all data access implementations that encapsulate
//! the storage and retrieval of data. Repositories are responsible for:
//! - Database interactions
//! - CRUD operations
//! - Query implementation
//! - Data transformation between database and domain models

// Import external types
use sqlx::PgPool;

// Re-export repository structs for easier access
pub mod auth_repository;
pub use auth_repository::AuthRepository;
pub mod auth_signup_repository; // Added auth_signup_repository
pub use auth_signup_repository::AuthSignupRepository; // Added re-export for AuthSignupRepository

// Additional repositories will be added here
// pub mod parking_repository;
// pub mod payment_repository;
// pub mod user_repository;

// Common repository utilities and interfaces
mod repository_utils {
    use sqlx::PgPool;
    use tracing::info;
    
    /// Check database connectivity
    pub async fn check_connectivity(pool: &PgPool) -> Result<(), sqlx::Error> {
        info!("Checking database connectivity");
        sqlx::query("SELECT 1").execute(pool).await?;
        info!("Database connection successful");
        Ok(())
    }
    
    /// Initialize repositories' common resources
    pub fn init_repositories() {
        info!("Initializing repository layer");
        // Perform any global repository initialization here
    }
}

/// Initialize the repository layer
pub fn init() {
    repository_utils::init_repositories();
}

/// Health check for repository connectivity
pub async fn health_check(pool: &PgPool) -> bool {
    repository_utils::check_connectivity(pool).await.is_ok()
}
