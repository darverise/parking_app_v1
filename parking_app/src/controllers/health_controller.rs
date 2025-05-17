// src/controllers/health_controller.rs
use actix_web::{get, HttpResponse, Responder};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: String,
    pub environment: String,
}

#[get("/health")]
pub async fn health_check() -> impl Responder {
    log::info!("health_check endpoint called");
    // 環境変数から環境情報を取得
    let environment: String = std::env::var("ENVIRONMENT").unwrap_or_else(|_| "development".to_string());
    
    let response = HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        environment,
    };
    
    HttpResponse::Ok().json(response)
}

#[get("/health/details")]
pub async fn health_details() -> impl Responder {
    log::info!("health_details endpoint called");
    let system_info = serde_json::json!({
        "status": "ok",
        "version": env!("CARGO_PKG_VERSION"),
        "rust_version": env!("CARGO_PKG_RUST_VERSION"),
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "uptime": std::process::id().to_string(),
    });
    
    HttpResponse::Ok().json(system_info)
}