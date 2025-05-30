use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use tracing::{debug, error};
use uuid::Uuid;

use crate::controllers::api_error::ApiError;

// JWTトークンのクレーム
#[derive(Debug, Serialize, Deserialize, Clone)]  // Cloneトレイトを追加
pub struct TokenClaims {
    pub sub: String,        // サブジェクト (ユーザーID)
    pub iat: usize,         // 発行時刻 (Issued At)
    pub exp: usize,         // 有効期限 (Expiration Time)
    pub user_type: String,  // ユーザータイプ (0:一般ユーザー, 1:オーナー, 2:管理者)
}

// リフレッシュトークンのクレーム
#[derive(Debug, Serialize, Deserialize, Clone)]  // Cloneトレイトを追加
pub struct RefreshTokenClaims {
    pub sub: String,  // サブジェクト (ユーザーID)
    pub iat: usize,   // 発行時刻 (Issued At)
    pub exp: usize,   // 有効期限 (Expiration Time)
    pub jti: String,  // JWT ID (一意のトークンID)
}

// JWT設定構造体
#[derive(Debug, Clone)]
pub struct JwtConfig {
    pub jwt_secret: String,                     // JWTシークレットキー
    pub jwt_refresh_secret: String,             // JWTリフレッシュシークレットキー
    pub jwt_expiration_hours: i64,              // JWT有効期限（時間）
    pub jwt_refresh_expiration_days: i64,       // JWTリフレッシュ有効期限（日数）
    pub is_development: bool,                   // 開発環境かどうか
}

impl JwtConfig {
    // 環境変数からJWT設定を作成
    pub fn from_env() -> Self {
        let is_development = is_development();
        
        Self {
            jwt_secret: get_jwt_secret(is_development),
            jwt_refresh_secret: get_jwt_refresh_secret(is_development),
            jwt_expiration_hours: get_jwt_expiration_hours(),
            jwt_refresh_expiration_days: get_jwt_refresh_expiration_days(),
            is_development,
        }
    }
}

// 開発環境かどうかを判定
fn is_development() -> bool {
    std::env::var("ENVIRONMENT")
        .unwrap_or_else(|_| "development".to_string())
        .to_lowercase() == "development"
}

// JWTシークレットキーを取得
fn get_jwt_secret(is_dev: bool) -> String {
    let default_key = if is_dev {
        "dev_jwt_secret_key_12345678901234567890".to_string()
    } else {
        panic!("本番環境ではJWT_SECRETを設定する必要があります！")
    };
    
    std::env::var("JWT_SECRET").unwrap_or_else(|_| {
        if !is_dev {
            panic!("本番環境ではJWT_SECRET環境変数が必要です！");
        }
        debug!("開発環境用のデフォルトJWTシークレットを使用します");
        default_key
    })
}

// JWTリフレッシュシークレットキーを取得
fn get_jwt_refresh_secret(is_dev: bool) -> String {
    let default_key = if is_dev {
        "dev_jwt_refresh_secret_key_12345678901234567890".to_string()
    } else {
        panic!("本番環境ではJWT_REFRESH_SECRETを設定する必要があります！")
    };
    
    std::env::var("JWT_REFRESH_SECRET").unwrap_or_else(|_| {
        if !is_dev {
            panic!("本番環境ではJWT_REFRESH_SECRET環境変数が必要です！");
        }
        debug!("開発環境用のデフォルトJWTリフレッシュシークレットを使用します");
        default_key
    })
}

// JWT有効期限（時間）を取得
fn get_jwt_expiration_hours() -> i64 {
    std::env::var("JWT_EXPIRATION_HOURS")
        .unwrap_or_else(|_| "24".to_string())
        .parse()
        .unwrap_or_else(|_| {
            debug!("JWT_EXPIRATION_HOURSが無効です。デフォルトの24時間を使用します");
            24
        })
}

// JWTリフレッシュ有効期限（日数）を取得
fn get_jwt_refresh_expiration_days() -> i64 {
    std::env::var("JWT_REFRESH_EXPIRATION_DAYS")
        .unwrap_or_else(|_| "30".to_string())
        .parse()
        .unwrap_or_else(|_| {
            debug!("JWT_REFRESH_EXPIRATION_DAYSが無効です。デフォルトの30日を使用します");
            30
        })
}

// JWTトークンを生成する
pub fn generate_jwt(user_id: &str, user_type: &str) -> Result<String, ApiError> {
    debug!("ユーザー: {}, タイプ: {} のJWTトークンを生成中", user_id, user_type);

    let config = JwtConfig::from_env();
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + Duration::hours(config.jwt_expiration_hours)).timestamp() as usize;

    let claims = TokenClaims {
        sub: user_id.to_string(),
        iat,
        exp,
        user_type: user_type.to_string(),
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(config.jwt_secret.as_bytes()),
    )
    .map_err(|e| {
        error!("JWTトークンの生成に失敗しました: {}", e);
        ApiError::InternalServerError
    })
}

// リフレッシュトークンを生成する
pub fn generate_refresh_token(user_id: &str) -> Result<String, ApiError> {
    debug!("ユーザー: {} のリフレッシュトークンを生成中", user_id);

    let config = JwtConfig::from_env();
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + Duration::days(config.jwt_refresh_expiration_days)).timestamp() as usize;

    let claims = RefreshTokenClaims {
        sub: user_id.to_string(),
        iat,
        exp,
        jti: Uuid::new_v4().to_string(),
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(config.jwt_refresh_secret.as_bytes()),
    )
    .map_err(|e| {
        error!("リフレッシュトークンの生成に失敗しました: {}", e);
        ApiError::InternalServerError
    })
}

// JWTトークンを検証する
pub fn verify_jwt(token: &str) -> Result<TokenClaims, ApiError> {
    debug!("JWTトークンを検証中");

    let config = JwtConfig::from_env();

    decode::<TokenClaims>(
        token,
        &DecodingKey::from_secret(config.jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map(|token_data| {
        debug!("JWTトークンの検証が成功しました");
        token_data.claims
    })
    .map_err(|e| {
        debug!("JWTトークンの検証に失敗しました: {}", e);
        ApiError::AuthenticationError("無効なトークンです".into())
    })
}

// リフレッシュトークンを検証する
pub fn verify_refresh_token(token: &str) -> Result<RefreshTokenClaims, ApiError> {
    debug!("リフレッシュトークンを検証中");

    let config = JwtConfig::from_env();

    decode::<RefreshTokenClaims>(
        token,
        &DecodingKey::from_secret(config.jwt_refresh_secret.as_bytes()),
        &Validation::default(),
    )
    .map(|token_data| {
        debug!("リフレッシュトークンの検証が成功しました");
        token_data.claims
    })
    .map_err(|e| {
        debug!("リフレッシュトークンの検証に失敗しました: {}", e);
        ApiError::AuthenticationError("無効なリフレッシュトークンです".into())
    })
}

// 設定情報を取得する（デバッグ用）
pub fn get_jwt_config_info() -> String {
    let config = JwtConfig::from_env();
    format!(
        "環境: {}, JWT有効期限: {}時間, リフレッシュ有効期限: {}日",
        if config.is_development { "開発環境" } else { "本番環境" },
        config.jwt_expiration_hours,
        config.jwt_refresh_expiration_days
    )
}
