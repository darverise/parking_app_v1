use actix_web::{HttpResponse, ResponseError};
use derive_more::Display;
use serde::Serialize;
use std::fmt;
use tracing::{debug, error, warn};

#[derive(Debug, Display)]
pub enum ApiError {
    #[display(fmt = "内部サーバーエラーが発生しました")]
    InternalServerError,

    #[display(fmt = "認証エラー: {}", _0)]
    AuthenticationError(String),

    #[display(fmt = "アクセス権限エラー: {}", _0)]
    AuthorizationError(String),

    #[display(fmt = "データベースエラー: {}", _0)]
    DatabaseError(String),

    #[display(fmt = "バリデーションエラー: {}", _0)]
    ValidationError(String),

    #[display(fmt = "リソースが見つかりません: {}", _0)]
    NotFoundError(String),

    #[display(fmt = "リクエストエラー: {}", _0)]
    BadRequestError(String),

    #[display(fmt = "重複エラー: {}", _0)]
    DuplicateError(String),
    
    #[display(fmt = "レート制限エラー: {}", _0)]
    RateLimitError(String),
    
    #[display(fmt = "サービス利用不可: {}", _0)]
    ServiceUnavailableError(String),
}

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
        let request_id = uuid::Uuid::new_v4().to_string();
        
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
            ApiError::BadRequestError(msg) => {
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
        }
        
        let error_response = ErrorResponse {
            code: status_code.as_u16(),
            message: self.to_string(),
            details,
            request_id: request_id.clone(), // 修正：ここ用 clone，保证后续还能用 request_id
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
            ApiError::DuplicateError(_) => StatusCode::CONFLICT,
            ApiError::RateLimitError(_) => StatusCode::TOO_MANY_REQUESTS,
            ApiError::ServiceUnavailableError(_) => StatusCode::SERVICE_UNAVAILABLE,
        }
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(error: sqlx::Error) -> ApiError {
        match error {
            sqlx::Error::RowNotFound => ApiError::NotFoundError("リソースが見つかりません".into()),
            _ => {
                error!("Database error: {:?}", error);
                ApiError::DatabaseError(error.to_string())
            }
        }
    }
}

impl From<jsonwebtoken::errors::Error> for ApiError {
    fn from(error: jsonwebtoken::errors::Error) -> ApiError {
        error!("JWT error: {:?}", error);
        ApiError::AuthenticationError("無効なトークンです".into())
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

impl fmt::Display for ErrorResponse {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{{code: {}, message: {}}}", self.code, self.message)
    }
}