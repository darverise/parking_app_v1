use actix_web::HttpResponse;
use serde::Serialize;
use std::collections::HashMap;
use tracing::debug;

/// APIレスポンスのヘッダー定数
/// 共通ヘッダー定数
pub mod headers {
    // 認証関連
    pub const AUTHORIZATION: &str = "Authorization";
    pub const X_API_KEY: &str = "X-Api-Key";

    // セキュリティ関連
    pub const X_CSRF_TOKEN: &str = "X-CSRF-Token";
    pub const X_FRAME_OPTIONS: &str = "X-Frame-Options";
    pub const X_CONTENT_TYPE_OPTIONS: &str = "X-Content-Type-Options";

    // コンテンツタイプ関連
    pub const CONTENT_TYPE: &str = "Content-Type";
    pub const CONTENT_TYPE_JSON: &str = "application/json";
    pub const ACCEPT: &str = "Accept";

    // モバイルアプリ特有
    pub const USER_AGENT: &str = "User-Agent";
    pub const X_DEVICE_ID: &str = "X-Device-ID";
    pub const X_APP_VERSION: &str = "X-App-Version";

    // 言語・地域化
    pub const ACCEPT_LANGUAGE: &str = "Accept-Language";
    pub const X_TIMEZONE: &str = "X-Timezone";

    // キャッシュ関連
    pub const IF_NONE_MATCH: &str = "If-None-Match";
    pub const ETAG: &str = "ETag";
    pub const CACHE_CONTROL: &str = "Cache-Control";

    // 追跡・分析
    pub const X_REQUEST_ID: &str = "X-Request-ID";
    pub const X_CORRELATION_ID: &str = "X-Correlation-ID";
}

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
    pub fn success(
        data: T,
        code: Option<u16>,
        message: Option<&str>,
        headers: Option<&[(&str, &str)]>,
    ) -> HttpResponse {
        let code = code.unwrap_or(200);
        debug!("Creating success response with code {}", code);

        let mut response = Self {
            code,
            message: message.unwrap_or("成功").to_string(),
            data: Some(data),
            headers: HashMap::new(),
        };

        // Add headers if provided
        if let Some(header_pairs) = headers {
            for &(key, value) in header_pairs {
                response.headers.insert(key.to_string(), value.to_string());
            }
        }

        response.to_http_response()
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
            _ => HttpResponse::build(
                actix_web::http::StatusCode::from_u16(self.code)
                    .unwrap_or(actix_web::http::StatusCode::OK),
            ),
        };

        // カスタムヘッダーを追加
        for (key, value) in &self.headers {
            builder.append_header((key.as_str(), value.as_str()));
        }

        builder.json(self)
    }

    /// 一般的なモバイルアプリヘッダーを追加
    /// 
    /// Parameters:
    /// - request_id: Option<&str> - リクエストID（デバッグ・分析用）
    /// - cache_ttl: Option<u32> - キャッシュの有効期間（秒）
    /// 
    /// # 使用例
    /// 
    /// ## 基本的な使用法
    /// ```
    /// use parking_app::controllers::api_response::{ApiResponse, headers};
    /// 
    /// // レスポンスの作成
    /// let mut response = ApiResponse::new(user_data);
    /// 
    /// // モバイルアプリ用のヘッダーを追加
    /// response.add_common_mobile_headers(Some("req-123-abc"), Some(300));
    /// ```
    /// 
    /// ## リクエストIDのみを設定
    /// ```
    /// let mut response = ApiResponse::new(user_data);
    /// response.add_common_mobile_headers(Some("req-123-abc"), None);
    /// ```
    /// 
    /// ## キャッシュ制御のみを設定
    /// ```
    /// let mut response = ApiResponse::new(user_data);
    /// response.add_common_mobile_headers(None, Some(600)); // 10分間キャッシュ
    /// ```
    /// 
    /// ## 他のメソッドとの連鎖
    /// ```
    /// let response = ApiResponse::new(user_data)
    ///     .add_common_mobile_headers(Some("req-123-abc"), Some(300))
    ///     .set_token_expiry(3600)
    ///     .with_message("データが正常に取得されました");
    /// ```
    pub fn add_common_mobile_headers(
        &mut self,
        request_id: Option<&str>,
        cache_ttl: Option<u32>,
    ) -> &mut Self {
        // リクエストIDの追加 (分析・デバッグ用)
        if let Some(id) = request_id {
            self.headers
                .insert(headers::X_REQUEST_ID.to_string(), id.to_string());
        }

        // キャッシュ制御の追加
        if let Some(ttl) = cache_ttl {
            self.headers.insert(
                headers::CACHE_CONTROL.to_string(),
                format!("max-age={}, public", ttl),
            );
        }

        self
    }

    /// 認証トークンの有効期限を設定
    pub fn set_token_expiry(&mut self, expires_in: u64) -> &mut Self {
        self.headers
            .insert("X-Token-Expires-In".to_string(), expires_in.to_string());
        self
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
pub fn success_responsex() -> HttpResponse {
    ApiResponse::<bool>::success(true, None, None, None)
}

/// 成功レスポンス (bool値のデータ)
/// Parameters:
/// - data: bool
pub fn success_response_with_bool(data: bool) -> HttpResponse {
    ApiResponse::<bool>::success(data, None, None, None)
}

/// 成功レスポンス (任意のデータ)
/// Parameters:
/// - data: T
pub fn success_response_for_data<T: Serialize>(data: T) -> HttpResponse {
    ApiResponse::<T>::success(data, None, None, None)
}

/// 成功レスポンス (任意のデータとメッセージ)
/// Parameters:
/// - data: T
/// - message: &str
pub fn success_response_for_data_message<T: Serialize>(data: T, message: &str) -> HttpResponse {
    ApiResponse::<T>::success(data, None, Some(message), None)
}

/// 成功レスポンス (任意のデータ、ステータスコード、メッセージ)
/// Parameters:
/// - data: T
/// - code: u16
/// - message: &str
pub fn success_response_for_data_code_message<T: Serialize>(
    data: T,
    code: u16,
    message: &str,
) -> HttpResponse {
    ApiResponse::<T>::success(data, Some(code), Some(message), None)
}

/// 成功レスポンス (任意のデータ、ステータスコード、メッセージ、ヘッダー)
///
/// Parameters:
/// - data: T - データ（boolまたは任意の型）
/// - code: Option<u16> - ステータスコード（Noneの場合は200が使用される）
/// - message: Option<&str> - レスポンスメッセージ（Noneの場合は "成功" が使用される）
/// - headers: Option<&[(&str, &str)]> - カスタムヘッダー（Noneの場合はヘッダーは追加されない）
///
/// # 使用例
///
/// ## 基本的な使用法（データのみ）
/// ```
/// use parking_app::controllers::api_response::success_response;
///
/// let user_data = UserData { id: 1, name: "山田太郎" };
/// let response = success_response(user_data, None, None, None);
/// ```
///
/// ## カスタムステータスコード付き
/// ```
/// let response = success_response(data, Some(201), None, None);
/// ```
///
/// ## カスタムメッセージ付き
/// ```
/// let response = success_response(data, None, Some("正常に処理されました"), None);
/// ```
///
/// ## カスタムヘッダー付き
/// ```
/// let custom_headers = &[
///     ("X-Request-ID", "abc-123-xyz"),
///     ("X-Rate-Limit-Remaining", "98")
/// ];
/// let response = success_response(data, None, None, Some(custom_headers));
/// ```
///
/// ## すべてのパラメータを使用
/// ```
/// let response = success_response(
///     data,
///     Some(200),
///     Some("データが正常に取得されました"),
///     Some(&[("X-Request-ID", "abc-123-xyz")])
/// );
/// ```
pub fn success_response<T: Serialize>(
    data: T,
    code: Option<u16>,
    message: Option<&str>,
    headers: Option<&[(&str, &str)]>,
) -> HttpResponse {
    ApiResponse::<T>::success(data, code, message, headers)
}
