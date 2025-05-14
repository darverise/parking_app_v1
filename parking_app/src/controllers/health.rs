use actix_web::{get, web, HttpResponse, Responder};
use serde::Serialize;
use tracing::{error, info};

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
    database_status: String,
    timestamp: String,
}

#[get("/health")]
async fn health_check(
    db: web::Data<crate::config::postgresql_database::PostgresDatabase>,
) -> impl Responder {
    info!("执行健康检查");

    // 检查数据库连接
    let db_status: &'static str = match sqlx::query("SELECT 1").fetch_one(db.pool()).await {
        Ok(_) => "connected",
        Err(e) => {
            error!("数据库健康检查失败: {}", e);
            "disconnected"
        }
    };

    // 获取当前时间
    let now = chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // 构建响应
    let response = HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        database_status: db_status.to_string(),
        timestamp: now,
    };

    // 返回JSON响应
    HttpResponse::Ok().json(response)
}

#[get("/api/version")]
async fn version() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "version": env!("CARGO_PKG_VERSION"),
        "name": env!("CARGO_PKG_NAME"),
        "build_time": chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string()
    }))
}

/// 配置健康检查API路由
pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(health_check).service(version);
}
