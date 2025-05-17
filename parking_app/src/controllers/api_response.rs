use actix_web::HttpResponse;
use serde::Serialize;
use std::collections::HashMap;
use tracing::debug;

/// APIレスポンスの標準フォーマット
#[derive(Debug, Serialize)]
pub struct ApiResponse<T>
where
    T: Serialize,
{
    pub code: u16,
    pub message: String,
    pub data: Option<T>,
    #[serde(skip)]
    headers: HashMap<String, String>,
}

impl<T: Serialize> ApiResponse<T> {
    /// 成功レスポンスを作成
    pub fn success(data: T) -> HttpResponse {
        debug!("Creating success response with code 200");
        Self {
            code: 200,
            message: "成功".to_string(),
            data: Some(data),
            headers: HashMap::new(),
        }
        .to_http_response()
    }

    /// 作成成功レスポンスを作成
    pub fn created(data: T) -> HttpResponse {
        debug!("Creating created response with code 201");
        Self {
            code: 201,
            message: "リソースが作成されました".to_string(),
            data: Some(data),
            headers: HashMap::new(),
        }
        .to_http_response()
    }

    /// カスタムメッセージを設定
    pub fn with_message(mut self, message: &str) -> Self {
        self.message = message.to_string();
        self
    }

    /// ヘッダーを追加
    pub fn add_header(&mut self, key: &str, value: &str) -> &mut Self {
        self.headers.insert(key.to_string(), value.to_string());
        self
    }

    /// HttpResponseに変換
    fn to_http_response(&self) -> HttpResponse {
        let mut builder = match self.code {
            200 => HttpResponse::Ok(),
            201 => HttpResponse::Created(),
            400 => HttpResponse::BadRequest(),
            401 => HttpResponse::Unauthorized(),
            403 => HttpResponse::Forbidden(),
            404 => HttpResponse::NotFound(),
            409 => HttpResponse::Conflict(),
            429 => HttpResponse::TooManyRequests(),
            500 => HttpResponse::InternalServerError(),
            _ => HttpResponse::build(actix_web::http::StatusCode::from_u16(self.code).unwrap_or(actix_web::http::StatusCode::OK)),
        };

        // カスタムヘッダーを追加
        for (key, value) in &self.headers {
            builder.append_header((key.as_str(), value.as_str()));
        }

        builder.json(self)
    }
}

// 単一型を持たないエラーレスポンス用の特別実装
impl ApiResponse<()> {
    /// エラーレスポンスを作成（データなし）
    pub fn error(code: u16, message: &str) -> HttpResponse {
        debug!("Creating error response with code {}: {}", code, message);
        Self {
            code,
            message: message.to_string(),
            data: None,
            headers: HashMap::new(),
        }
        .to_http_response()
    }
    
    /// 認証エラーレスポンスを作成
    pub fn unauthorized(message: &str) -> HttpResponse {
        Self::error(401, message)
    }
    
    /// 権限エラーレスポンスを作成
    pub fn forbidden(message: &str) -> HttpResponse {
        Self::error(403, message)
    }
    
    /// 見つからないエラーレスポンスを作成
    pub fn not_found(message: &str) -> HttpResponse {
        Self::error(404, message)
    }
    
    /// バリデーションエラーレスポンスを作成
    pub fn validation_error(message: &str) -> HttpResponse {
        Self::error(400, message)
    }
    
    /// サーバーエラーレスポンスを作成
    pub fn server_error(message: &str) -> HttpResponse {
        Self::error(500, message)
    }
}

// 一般的なエラーレスポンス用の汎用関数
pub fn error_response<S: AsRef<str>>(code: u16, message: S) -> HttpResponse {
    ApiResponse::<()>::error(code, message.as_ref())
}

// 成功レスポンス（データなし）用の汎用関数
pub fn success_response() -> HttpResponse {
    ApiResponse::<bool>::success(true)
}
