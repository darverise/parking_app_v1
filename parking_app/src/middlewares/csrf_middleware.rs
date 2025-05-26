use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpRequest, ResponseError,
    cookie::{Cookie, SameSite},
    body::EitherBody,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use std::collections::HashSet;
use std::env;
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::{debug, error, warn};
use rand::distr::Alphanumeric;
use rand::Rng;

/// CSRFミドルウェア - クロスサイトリクエストフォージェリ攻撃を防御
pub struct CsrfMiddleware {
    exempt_paths: HashSet<String>,
}

impl CsrfMiddleware {
    /// 新しいCSRFミドルウェアインスタンスを作成
    pub fn new() -> Self {
        Self {
            exempt_paths: HashSet::new(),
        }
    }

    /// 指定されたパスをCSRFチェックから除外
    pub fn exempt<S: Into<String>>(mut self, path: S) -> Self {
        self.exempt_paths.insert(path.into());
        self
    }

    /// 新しいCSRFトークンを生成（開発モードでは固定トークン）
    pub fn generate_token() -> String {
        let is_dev_mode = env::var("ENVIRONMENT")
            .map(|env| env.to_lowercase() == "development")
            .unwrap_or_else(|_| env::var("DEBUG_MODE")
                .map(|debug| debug.to_lowercase() == "true")
                .unwrap_or(false));

        if is_dev_mode {
            let fixed_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
            debug!("開発環境: 固定CSRFトークンを使用");
            return fixed_token.to_string();
        }

        // 32文字のランダム文字列を生成
        let rand_string: String = rand::rng()
            .sample_iter(&Alphanumeric)
            .take(32)
            .map(char::from)
            .collect();

        // 現在のタイムスタンプを取得
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let token = format!("{}-{}", rand_string, timestamp);
        debug!("CSRFトークンを生成しました");
        token
    }

    /// リクエストからCSRFトークンを取得（ヘッダーまたはクッキーから）
    pub fn get_token_from_request(req: &HttpRequest) -> Option<String> {
        // ヘッダーからトークンを検索
        if let Some(header_token) = req.headers().get("X-CSRF-Token") {
            if let Ok(token_str) = header_token.to_str() {
                debug!("CSRFトークンをヘッダーから取得");
                return Some(token_str.to_string());
            }
        }

        // クッキーからトークンを検索
        if let Some(cookie) = req.cookie("csrf_token") {
            debug!("CSRFトークンをクッキーから取得");
            return Some(cookie.value().to_string());
        }

        debug!("CSRFトークンが見つかりませんでした");
        None
    }

    /// CSRFトークンを検証（ヘッダーとクッキーの一致を確認）
    pub fn validate_token(header_token: Option<&str>, cookie_token: Option<&str>) -> bool {
        let is_dev_mode = env::var("ENVIRONMENT")
            .map(|env| env.to_lowercase() == "development")
            .unwrap_or_else(|_| env::var("DEBUG_MODE")
                .map(|debug| debug.to_lowercase() == "true")
                .unwrap_or(false));

        // 開発モードでは固定トークンをチェック
        if is_dev_mode {
            let fixed_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
            
            if let Some(h) = header_token {
                if h == fixed_token {
                    debug!("開発環境: 固定CSRFトークンが検証されました");
                    return true;
                }
            }
            
            if let Some(c) = cookie_token {
                if c == fixed_token {
                    debug!("開発環境: 固定CSRFトークンが検証されました");
                    return true;
                }
            }
        }

        // 本番環境での検証
        match (header_token, cookie_token) {
            (Some(h), Some(c)) => {
                let is_valid = h == c && !h.is_empty() && Self::validate_token_with_expiry(h);
                if !is_valid {
                    warn!("CSRFトークンが一致しないか無効です");
                }
                is_valid
            },
            _ => {
                warn!("CSRFトークンが不足しています");
                false
            }
        }
    }

    /// リクエストからCSRFトークンを検証
    pub fn validate_request(req: &HttpRequest) -> bool {
        let is_dev_mode = env::var("ENVIRONMENT")
            .map(|env| env.to_lowercase() == "development")
            .unwrap_or_else(|_| env::var("DEBUG_MODE")
                .map(|debug| debug.to_lowercase() == "true")
                .unwrap_or(false));

        let header_token = req.headers().get("X-CSRF-Token")
            .and_then(|h| h.to_str().ok());
        let cookie_token = req.cookie("csrf_token")
            .map(|c| c.value().to_string());

        debug!("CSRFトークンを検証中: 開発モード={}", is_dev_mode);

        // 開発モードでの固定トークン検証
        if is_dev_mode {
            let fixed_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
            
            if let Some(h_token) = header_token {
                if h_token == fixed_token {
                    debug!("開発環境: 固定CSRFトークンが検証されました");
                    return true;
                }
            }
            
            if let Some(ref c_token) = cookie_token {
                if c_token == fixed_token {
                    debug!("開発環境: 固定CSRFトークンが検証されました");
                    return true;
                }
            }
        }

        Self::validate_token(header_token, cookie_token.as_deref())
    }

    /// CSRFトークンクッキーを構築
    pub fn build_csrf_cookie(token: &str) -> Cookie<'static> {
        debug!("CSRFクッキーを構築中");
        Cookie::build("csrf_token", token.to_string())
            .http_only(false) // JavaScriptからアクセス可能
            .same_site(SameSite::Lax) // CSRF攻撃を防ぐ
            .path("/")
            .max_age(actix_web::cookie::time::Duration::hours(24))
            .secure(false) // HTTPSでのみ送信（本番では true に設定）
            .finish()
    }

    /// 開発用の固定CSRFクッキーを構築
    pub fn build_fixed_csrf_cookie(token: &str) -> Cookie<'static> {
        debug!("開発環境用の固定CSRFクッキーを構築中");
        Cookie::build("csrf_token", token.to_string())
            .http_only(false)
            .same_site(SameSite::Lax)
            .path("/")
            .max_age(actix_web::cookie::time::Duration::days(365))
            .secure(false)
            .finish()
    }

    /// トークンの形式を検証
    pub fn is_valid_format(token: &str) -> bool {
        if token.is_empty() {
            return false;
        }

        let parts: Vec<&str> = token.split('-').collect();
        if parts.len() != 2 {
            return false;
        }

        // 最初の部分は32文字の英数字である必要がある
        if parts[0].len() != 32 || !parts[0].chars().all(|c| c.is_alphanumeric()) {
            return false;
        }

        // 2番目の部分は有効なタイムスタンプである必要がある
        parts[1].parse::<u64>().is_ok()
    }

    /// トークンの有効期限をチェック（24時間）
    pub fn is_token_expired(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            return true;
        }

        let parts: Vec<&str> = token.split('-').collect();
        if let Ok(token_timestamp) = parts[1].parse::<u64>() {
            let current_timestamp = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();

            let is_expired = current_timestamp - token_timestamp > 86400; // 24時間
            if is_expired {
                debug!("CSRFトークンの有効期限が切れています");
            }
            is_expired
        } else {
            true
        }
    }

    /// 有効期限チェック付きでトークンを検証
    pub fn validate_token_with_expiry(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            warn!("無効なCSRFトークン形式");
            return false;
        }

        if Self::is_token_expired(token) {
            warn!("CSRFトークンの有効期限が切れています");
            return false;
        }

        debug!("CSRFトークンが有効期限チェック付きで検証されました");
        true
    }
}

/// CSRFミドルウェアサービス実装
pub struct CsrfMiddlewareService<S> {
    service: S,
    exempt_paths: HashSet<String>,
}

impl<S, B> Service<ServiceRequest> for CsrfMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        debug!("CSRFミドルウェアが処理中: {}", req.path());

        // 除外パスのチェック
        if self.exempt_paths.contains(req.path()) {
            debug!("除外パスのためCSRFチェックをスキップ");
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res.map_into_left_body())
            });
        }

        let method = req.method().clone();
        // 安全なメソッド（GET, HEAD, OPTIONS）はCSRFチェックをスキップ
        if method.is_safe() {
            debug!("安全なメソッドのためCSRFチェックをスキップ");
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res.map_into_left_body())
            });
        }

        // CSRF検証実行
        let is_valid = CsrfMiddleware::validate_request(req.request());

        if !is_valid {
            error!("CSRF検証が失敗しました: {} {}", method, req.path());
            
            // CSRF検証失敗時の適切なエラーレスポンスを返す
            use crate::controllers::api_error::ApiError;
            
            let csrf_error = ApiError::AuthorizationError(
                "CSRFトークンの検証に失敗しました。有効なCSRFトークンが必要です。".to_string()
            );
            
            let error_response = csrf_error.error_response();
            
            return Box::pin(async move {
                Ok(req.into_response(error_response).map_into_right_body())
            });
        }

        debug!("CSRF検証が成功しました: {} {}", method, req.path());
        let fut = self.service.call(req);
        Box::pin(async move {
            let res = fut.await?;
            Ok(res.map_into_left_body())
        })
    }
}

impl<S, B> Transform<S, ServiceRequest> for CsrfMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type InitError = ();
    type Transform = CsrfMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        debug!("CSRFミドルウェアを初期化中");
        ready(Ok(CsrfMiddlewareService { 
            service,
            exempt_paths: self.exempt_paths.clone(),
        }))
    }
}



//// テストモジュール
/// # テストは `cargo test` で実行できます。
#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::test::TestRequest;

    #[test]
    fn test_generate_token() {
        std::env::set_var("ENVIRONMENT", "development");
        let token = CsrfMiddleware::generate_token();
        assert_eq!(token, "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404");

        std::env::remove_var("ENVIRONMENT");
        let token = CsrfMiddleware::generate_token();
        assert!(!token.is_empty());
        assert!(CsrfMiddleware::is_valid_format(&token));
    }

    #[test]
    fn test_token_format_validation() {
        let valid_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
        assert!(CsrfMiddleware::is_valid_format(valid_token));

        let invalid_tokens = vec![
            "",
            "short-123",
            "toolongabcdefghijklmnopqrstuvwxyz123456-123",
            "validlength12345678901234567890-notanumber",
            "no-dash-here",
        ];

        for token in invalid_tokens {
            assert!(!CsrfMiddleware::is_valid_format(token), "トークンが無効であるべき: {}", token);
        }
    }

    #[test]
    fn test_validate_token() {
        let token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
        assert!(CsrfMiddleware::validate_token(Some(token), Some(token)));
        assert!(!CsrfMiddleware::validate_token(Some(token), Some("different")));
        assert!(!CsrfMiddleware::validate_token(Some(token), None));
        assert!(!CsrfMiddleware::validate_token(None, Some(token)));
        assert!(!CsrfMiddleware::validate_token(None, None));
    }

    #[actix_web::test]
    async fn test_get_token_from_request() {
        let req = TestRequest::default()
            .insert_header(("X-CSRF-Token", "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404"))
            .to_http_request();

        let token = CsrfMiddleware::get_token_from_request(&req);
        assert_eq!(token, Some("BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404".to_string()));

        let req = TestRequest::default()
            .cookie(Cookie::new("csrf_token", "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404"))
            .to_http_request();

        let token = CsrfMiddleware::get_token_from_request(&req);
        assert_eq!(token, Some("BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404".to_string()));
    }

    #[test]
    fn test_token_expiry() {
        let valid_token = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";
        assert!(!CsrfMiddleware::is_token_expired(valid_token));

        let expired_token = "abcdefghijklmnopqrstuvwxyz123456-1234567890";
        assert!(CsrfMiddleware::is_token_expired(expired_token));
    }
}
