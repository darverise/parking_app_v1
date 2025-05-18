use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use tracing::{debug, error};
use uuid::Uuid;

use crate::controllers::api_error::ApiError;

// JWTトークンのクレーム
#[derive(Debug, Serialize, Deserialize, Clone)]  // Cloneトレイトを追加
pub struct TokenClaims {
    pub sub: String,        // Subject (ユーザーID)
    pub iat: usize,         // Issued At (発行時刻)
    pub exp: usize,         // Expiration Time (有効期限)
    pub user_type: String,  // ユーザータイプ (0:一般ユーザー, 1:オーナー, 2:管理者)
}

// リフレッシュトークンのクレーム
#[derive(Debug, Serialize, Deserialize, Clone)]  // Cloneトレイトを追加
pub struct RefreshTokenClaims {
    pub sub: String,  // Subject (ユーザーID)
    pub iat: usize,   // Issued At (発行時刻)
    pub exp: usize,   // Expiration Time (有効期限)
    pub jti: String,  // JWT ID (一意のトークンID)
}

// JWTトークンを生成する
pub fn generate_jwt(user_id: &str, user_type: &str) -> Result<String, ApiError> {
    debug!("Generating JWT token for user: {}, type: {}", user_id, user_type);
    
    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "default_jwt_secret_key".to_string());
    
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + Duration::hours(24)).timestamp() as usize; // 24時間の有効期限
    
    let claims = TokenClaims {
        sub: user_id.to_string(),
        iat,
        exp,
        user_type: user_type.to_string(),
    };

    match encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_bytes()),
    ) {
        Ok(token) => Ok(token),
        Err(e) => {
            error!("Failed to generate JWT token: {}", e);
            Err(ApiError::InternalServerError)
        }
    }
}

// リフレッシュトークンを生成する
pub fn generate_refresh_token(user_id: &str) -> Result<String, ApiError> {
    debug!("Generating refresh token for user: {}", user_id);
    
    let jwt_secret = std::env::var("JWT_REFRESH_SECRET")
        .unwrap_or_else(|_| "default_jwt_refresh_secret_key".to_string());
    
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + Duration::days(30)).timestamp() as usize; // 30日の有効期限
    
    let claims = RefreshTokenClaims {
        sub: user_id.to_string(),
        iat,
        exp,
        jti: Uuid::new_v4().to_string(),
    };

    match encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_bytes()),
    ) {
        Ok(token) => Ok(token),
        Err(e) => {
            error!("Failed to generate refresh token: {}", e);
            Err(ApiError::InternalServerError)
        }
    }
}

// JWTトークンを検証する
pub fn verify_jwt(token: &str) -> Result<TokenClaims, ApiError> {
    debug!("Verifying JWT token");
    
    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "default_jwt_secret_key".to_string());
    
    match decode::<TokenClaims>(
        token,
        &DecodingKey::from_secret(jwt_secret.as_bytes()),
        &Validation::default(),
    ) {
        Ok(token_data) => {
            debug!("JWT token verified successfully");
            Ok(token_data.claims)
        },
        Err(e) => {
            debug!("JWT token verification failed: {}", e);
            Err(ApiError::AuthenticationError("無効なトークンです".into()))
        }
    }
}

// リフレッシュトークンを検証する
pub fn verify_refresh_token(token: &str) -> Result<RefreshTokenClaims, ApiError> {
    debug!("Verifying refresh token");
    
    let jwt_secret = std::env::var("JWT_REFRESH_SECRET")
        .unwrap_or_else(|_| "default_jwt_refresh_secret_key".to_string());
    
    match decode::<RefreshTokenClaims>(
        token,
        &DecodingKey::from_secret(jwt_secret.as_bytes()),
        &Validation::default(),
    ) {
        Ok(token_data) => {
            debug!("Refresh token verified successfully");
            Ok(token_data.claims)
        },
        Err(e) => {
            debug!("Refresh token verification failed: {}", e);
            Err(ApiError::AuthenticationError("無効なリフレッシュトークンです".into()))
        }
    }
}
