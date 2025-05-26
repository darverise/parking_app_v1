//! CSRFトークンAPIコントローラー
//! フロントエンドは /v1/api/auth/csrf-token からCSRFトークンを取得できます
use actix_web::{get, HttpRequest, HttpResponse, Responder};
use serde_json::json;
use tracing::debug;

use crate::middlewares::csrf_middleware::CsrfMiddleware;

/// GET /v1/api/auth/csrf-token
/// 新しいCSRFトークンを返し、Cookieに設定します
/// 開発環境では固定値を使用
#[get("/csrf-token")]
pub async fn get_csrf_token(_req: HttpRequest) -> impl Responder {
    debug!("CSRFトークンを生成中...");
    
    // Flutter開発用に固定値を使用
    let csrf_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404".to_string();
    let cookie = CsrfMiddleware::build_fixed_csrf_cookie(&csrf_token);

    debug!("固定CSRFトークンを返却: {}", &csrf_token[..8]);
    
    HttpResponse::Ok()
        .cookie(cookie)
        .json(json!({
            "success": true,
            "csrf_token": csrf_token,
            "message": "CSRFトークンの生成に成功しました。"
        }))
}
