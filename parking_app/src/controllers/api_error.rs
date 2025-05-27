use actix_web::{HttpResponse, ResponseError};
use derive_more::Display;
use serde::Serialize;
use std::fmt::{self, Debug};
use tracing::{debug, error, warn};
use uuid::Uuid;

/// API エラー列挙型
/// アプリケーション全体で使用される統一的なエラータイプ
#[derive(Debug, Display)]
pub enum ApiError {
    #[display(fmt = "内部サーバーエラーが発生しました")]
    InternalServerError,

    #[display(fmt = "認証エラー: {}", _0)]
    AuthenticationError(String),

    #[display(fmt = "アクセス権限エラー: {}", _0)]
    AuthorizationError(String),

    #[display(fmt = "CSRFトークンエラー: {}", _0)]
    CsrfValidationError(String),

    #[display(fmt = "データベースエラー: {}", _0)]
    DatabaseError(String),

    #[display(fmt = "バリデーションエラー: {}", _0)]
    ValidationError(String),

    #[display(fmt = "リソースが見つかりません: {}", _0)]
    NotFoundError(String),

    #[display(fmt = "リクエストエラー: {}", _0)]
    BadRequestError(String),
    
    #[display(fmt = "リクエストエラー: {}", _0)]
    BadRequest(String),

    #[display(fmt = "重複エラー: {}", _0)]
    DuplicateError(String),
    
    #[display(fmt = "レート制限エラー: {}", _0)]
    RateLimitError(String),
    
    #[display(fmt = "サービス利用不可: {}", _0)]
    ServiceUnavailableError(String),
    
    #[display(fmt = "セッションエラー: {}", _0)]
    SessionError(String),
    
    #[display(fmt = "トークンエラー: {}", _0)]
    TokenError(String),
}

/// エラーレスポンスのJSON構造
#[derive(Serialize)]
struct ErrorResponse {
    code: u16,
    message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<String>,
    request_id: String,
}

impl ResponseError for ApiError {
    fn error_response(&self) -> HttpResponse {
        let status_code = self.status_code();
        
        // リクエストIDの生成
        let request_id = Uuid::new_v4().to_string();
        
        // エラーの詳細情報（開発環境のみ表示）
        let details = if cfg!(debug_assertions) {
            Some(format!("{:?}", self))
        } else {
            None
        };
        
        // エラーの重大度に応じてログを出力
        match self {
            ApiError::InternalServerError => {
                error!(request_id = %request_id, "Internal server error occurred");
            },
            ApiError::DatabaseError(msg) => {
                error!(request_id = %request_id, error = %msg, "Database error occurred");
            },
            ApiError::AuthenticationError(msg) => {
                warn!(request_id = %request_id, error = %msg, "Authentication error");
            },
            ApiError::AuthorizationError(msg) => {
                warn!(request_id = %request_id, error = %msg, "Authorization error");
            },
            ApiError::ValidationError(msg) | 
            ApiError::BadRequestError(msg) |
            ApiError::BadRequest(msg) => {
                debug!(request_id = %request_id, error = %msg, "Client error");
            },
            ApiError::NotFoundError(msg) => {
                debug!(request_id = %request_id, error = %msg, "Resource not found");
            },
            ApiError::DuplicateError(msg) => {
                debug!(request_id = %request_id, error = %msg, "Duplicate resource");
            },
            ApiError::RateLimitError(msg) => {
                warn!(request_id = %request_id, error = %msg, "Rate limit exceeded");
            },
            ApiError::ServiceUnavailableError(msg) => {
                error!(request_id = %request_id, error = %msg, "Service unavailable");
            },
            ApiError::SessionError(msg) => {
                warn!(request_id = %request_id, error = %msg, "Session error");
            },
            ApiError::TokenError(msg) => {
                warn!(request_id = %request_id, error = %msg, "Token error");
            },
            ApiError::CsrfValidationError(msg) => {
                warn!(request_id = %request_id, error = %msg, "CSRF validation error");
            },
        }
        
        let error_response = ErrorResponse {
            code: status_code.as_u16(),
            message: self.to_string(),
            details,
            request_id: request_id.clone(),
        };
        
        HttpResponse::build(status_code)
            .insert_header(("X-Request-ID", request_id))
            .json(error_response)
    }

    fn status_code(&self) -> actix_web::http::StatusCode {
        use actix_web::http::StatusCode;
        match self {
            ApiError::InternalServerError => StatusCode::INTERNAL_SERVER_ERROR,
            ApiError::AuthenticationError(_) => StatusCode::UNAUTHORIZED,
            ApiError::AuthorizationError(_) => StatusCode::FORBIDDEN,
            ApiError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            ApiError::ValidationError(_) => StatusCode::BAD_REQUEST,
            ApiError::NotFoundError(_) => StatusCode::NOT_FOUND,
            ApiError::BadRequestError(_) => StatusCode::BAD_REQUEST,
            ApiError::BadRequest(_) => StatusCode::BAD_REQUEST,
            ApiError::DuplicateError(_) => StatusCode::CONFLICT,
            ApiError::RateLimitError(_) => StatusCode::TOO_MANY_REQUESTS,
            ApiError::ServiceUnavailableError(_) => StatusCode::SERVICE_UNAVAILABLE,
            ApiError::SessionError(_) => StatusCode::UNAUTHORIZED,
            ApiError::TokenError(_) => StatusCode::UNAUTHORIZED,
            ApiError::CsrfValidationError(_) => StatusCode::FORBIDDEN,
        }
    }
}

// 共通のエラー型からのコンバージョン
impl From<sqlx::Error> for ApiError {
    fn from(error: sqlx::Error) -> ApiError {
        match error {
            sqlx::Error::RowNotFound => ApiError::NotFoundError("リソースが見つかりません".into()),
            sqlx::Error::Database(db_err) => {
                // 一意性制約違反を検出（PostgreSQL固有）
                if let Some(code) = db_err.code() {
                    if code == "23505" {  // 一意性制約違反コード
                        return ApiError::DuplicateError("この値は既に使用されています".into());
                    }
                }
                error!("Database error: {:?}", db_err);
                ApiError::DatabaseError(format!("データベースエラー: {}", db_err))
            },
            sqlx::Error::PoolClosed | sqlx::Error::PoolTimedOut => {
                error!("Database connection error: {:?}", error);
                ApiError::ServiceUnavailableError("サービスが一時的に利用できません。後でお試しください。".into())
            },
            _ => {
                error!("Database error: {:?}", error);
                ApiError::DatabaseError(format!("データベースエラー: {}", error))
            }
        }
    }
}

impl From<jsonwebtoken::errors::Error> for ApiError {
    fn from(error: jsonwebtoken::errors::Error) -> ApiError {
        match error.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                ApiError::TokenError("トークンの有効期限が切れています".into())
            },
            jsonwebtoken::errors::ErrorKind::InvalidToken => {
                ApiError::TokenError("無効なトークンです".into())
            },
            _ => {
                error!("JWT error: {:?}", error);
                ApiError::AuthenticationError("認証エラーが発生しました".into())
            }
        }
    }
}

impl From<bcrypt::BcryptError> for ApiError {
    fn from(error: bcrypt::BcryptError) -> ApiError {
        error!("Bcrypt error: {:?}", error);
        ApiError::InternalServerError
    }
}

impl From<std::io::Error> for ApiError {
    fn from(error: std::io::Error) -> ApiError {
        error!("IO error: {:?}", error);
        ApiError::InternalServerError
    }
}

impl From<uuid::Error> for ApiError {
    fn from(error: uuid::Error) -> ApiError {
        ApiError::ValidationError(format!("無効なUUID: {}", error))
    }
}

impl From<anyhow::Error> for ApiError {
    fn from(error: anyhow::Error) -> ApiError {
        error!("Anyhow error: {:?}", error);
        ApiError::InternalServerError
    }
}

impl fmt::Display for ErrorResponse {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{{code: {}, message: {}}}", self.code, self.message)
    }
}