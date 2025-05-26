//! Service layer implementation for the parking application.
//!
//! This module contains all service implementations that encapsulate the business logic
//! of the application. Services are responsible for coordinating between repositories
//! and controllers, implementing validation rules, and applying business rules.

// services/mod.rs - サービスモジュール

pub mod auth_service;
pub mod auth_signup_service; // Added auth_signup_service
pub mod email_service;
pub mod sms_service;

// 共通で使用するサービスの再エクスポート
pub use auth_service::AuthService;
pub use auth_signup_service::AuthSignupService; // Added re-export for AuthSignupService
pub use email_service::EmailService;
pub use sms_service::SmsService;

// Common service utilities and interfaces
mod service_utils {
    use tracing::info;
    
    /// Initialize all services and their dependencies
    pub fn init_services() {
        info!("Initializing service layer");
        // Perform any global service initialization here
    }
}

/// Initialize the service layer
pub fn init() {
    service_utils::init_services();
}
