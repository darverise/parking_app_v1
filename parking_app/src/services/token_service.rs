// 共通Token工具类
// src/utils/token_service.rs
use actix_web::HttpRequest;
use crate::middlewares::jwt::verify_jwt;
use crate::controllers::api_error::ApiError;
use serde_json::json;
use reqwest::Client;
use std::env;

pub struct TokenService;

impl TokenService {
    /// 从请求中获取access token（优先Authorization Bearer, 其次Cookie）
    pub fn get_access_token(req: &HttpRequest) -> Option<String> {
        // 1. Header
        if let Some(auth_header) = req.headers().get("Authorization") {
            if let Ok(auth_str) = auth_header.to_str() {
                if auth_str.starts_with("Bearer ") {
                    return Some(auth_str[7..].to_string());
                }
            }
        }
        // 2. Cookie
        if let Some(cookie) = req.cookie("access_token") {
            return Some(cookie.value().to_string());
        }
        None
    }

    /// 校验access token（JWT）
    pub fn validate_access_token(token: &str) -> Result<(), ApiError> {
        verify_jwt(token).map(|_| ())
    }

    /// 刷新token（调用刷新接口，返回新token）
    pub async fn refresh_token(refresh_token: &str) -> Result<(String, String, i64), ApiError> {
        // 假设刷新接口为 /api/auth/refresh-token
        let api_url = env::var("REFRESH_TOKEN_URL").unwrap_or_else(|_| "/api/auth/refresh-token".to_string());
        let backend_url = env::var("BACKEND_BASE_URL").unwrap_or_else(|_| "http://localhost:8080".to_string());
        let url = format!("{}{}", backend_url, api_url);
        let client = Client::new();
        let resp = client
            .post(&url)
            .json(&json!({"refresh_token": refresh_token}))
            .send()
            .await
            .map_err(|e| ApiError::InternalServerError)?;
        let status = resp.status();
        let json: serde_json::Value = resp.json().await.map_err(|_e| ApiError::InternalServerError)?;
        if status.is_success() {
            let access_token = json["access_token"].as_str().unwrap_or("").to_string();
            let refresh_token = json["refresh_token"].as_str().unwrap_or("").to_string();
            let expires_in = json["expires_in"].as_i64().unwrap_or(3600);
            Ok((access_token, refresh_token, expires_in))
        } else {
            Err(ApiError::TokenError("Refresh token invalid or expired".to_string()))
        }
    }
}
