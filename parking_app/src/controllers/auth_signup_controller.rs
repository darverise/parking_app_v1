use actix_web::{
    post, web::{self, Data, Json}, HttpRequest, Responder, ResponseError
};
use actix_web::http::StatusCode;
use tracing::{debug, error, instrument, warn};

use crate::{
    models::auth_signup_model::{OwnerSignupRequest, UserSignupRequest}
};
use crate::services::auth_signup_service::AuthSignupService;
use crate::controllers::api_response::ApiResponse;
use crate::controllers::api_error::ApiError;

/// 一般ユーザー新規登録エンドポイント
///
/// CSRFトークン検証、包括的な入力検証、構造化されたAPIレスポンスを提供する
/// ユーザー登録処理を行います。
///
/// # エンドポイント
/// `POST /api/auth/signup/user`
///
/// # 必要なヘッダー
/// - `X-CSRF-Token`: CSRF攻撃防止のための検証トークン
/// - `Content-Type`: application/json
///
/// # レスポンス
/// - `201 Created`: ユーザー登録成功、認証トークンを含む
/// - `400 Bad Request`: 無効な入力データまたはCSRFトークン不備
/// - `409 Conflict`: メールアドレスまたは電話番号が既に使用されている
/// - `500 Internal Server Error`: サーバー処理エラー
#[post("/user")]
#[instrument(skip(service), fields(email = %req.email))]
pub async fn register_user_controller(
    req: web::Json<UserSignupRequest>,
    service: Data<AuthSignupService>,
) -> impl Responder {
    let request_data = req.into_inner();
    
    debug!(
        "ユーザー登録リクエストを受信 - メール: {}, 氏名: {}", 
        request_data.email, 
        request_data.full_name
    );

    // 入力データの検証
    if let Err(validation_error) = validate_user_signup_request(&request_data) {
        warn!("ユーザー登録の入力検証に失敗: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }

    // ユーザー登録処理の実行
    match service.register_user(request_data).await {
        Ok(signup_response) => {
            debug!(
                "ユーザー登録が成功 - メール: {}, ユーザーID: {}", 
                signup_response.email, 
                signup_response.id
            );
            ApiResponse::success(
                signup_response, 
                Some(StatusCode::CREATED.as_u16()), 
                Some("ユーザー登録が正常に完了しました。メール認証を行ってください。"),
                None
            )
        }
        Err(api_err) => {
            error!("ユーザー登録に失敗: {}", api_err);
            
            match &api_err {
                ApiError::DuplicateError(_) => {
                    warn!("重複するユーザー登録の試行");
                }
                ApiError::InternalServerError => {
                    error!("ユーザー登録処理中の内部サーバーエラー");
                }
                _ => {
                    error!("ユーザー登録中の予期しないエラー: {:?}", api_err);
                }
            }
            api_err.error_response()
        }
    }
}

/// 駐車場オーナー新規登録エンドポイント
///
/// 駐車場管理に必要な追加フィールドを含む、包括的な検証を行う
/// オーナー登録処理を提供します。
///
/// # エンドポイント
/// `POST /api/auth/signup/owner`
///
/// # 必要なヘッダー
/// - `X-CSRF-Token`: CSRF攻撃防止のための検証トークン
/// - `Content-Type`: application/json
///
/// # レスポンス
/// - `201 Created`: オーナー登録成功、認証トークンを含む
/// - `400 Bad Request`: 無効な入力データまたはCSRFトークン不備
/// - `409 Conflict`: メールアドレスまたは電話番号が既に使用されている
/// - `500 Internal Server Error`: サーバー処理エラー
#[post("/signup/owner")]
#[instrument(skip(service), fields(email = %req_body.email, registrant_type = %req_body.registrant_type))]
pub async fn register_owner_controller(
    service: Data<AuthSignupService>,
    req_body: Json<OwnerSignupRequest>,
    req: HttpRequest,
) -> impl Responder {
    let request_data = req_body.into_inner();
    let connection_info = req.connection_info();
    let client_ip = connection_info.realip_remote_addr().unwrap_or("不明");

    debug!(
        "オーナー登録リクエストを受信 - メール: {}, タイプ: {}, IP: {}", 
        request_data.email,
        request_data.registrant_type,
        client_ip
    );

    // 入力データの検証
    if let Err(validation_error) = validate_owner_signup_request(&request_data) {
        warn!("オーナー登録の入力検証に失敗: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }

    // オーナー登録処理の実行
    match service.register_owner(request_data).await {
        Ok(signup_response) => {
            debug!(
                "オーナー登録が成功 - メール: {}, オーナーID: {}, タイプ: {}", 
                signup_response.email, 
                signup_response.id,
                signup_response.user_type
            );
            ApiResponse::success(
                signup_response, 
                Some(StatusCode::CREATED.as_u16()), 
                Some("オーナー登録が正常に完了しました。メール認証後、駐車場の登録が可能になります。"),
                None
            )
        }
        Err(api_err) => {
            error!("オーナー登録に失敗: {}", api_err);
            
            match &api_err {
                ApiError::DuplicateError(_) => {
                    warn!("重複するオーナー登録の試行 - IP: {}", client_ip);
                }
                ApiError::InternalServerError => {
                    error!("オーナー登録処理中の内部サーバーエラー");
                }
                _ => {
                    error!("オーナー登録中の予期しないエラー: {:?}", api_err);
                }
            }
            api_err.error_response()
        }
    }
}

// ===== 入力検証ヘルパー関数 =====

/// ユーザー登録リクエストデータの検証
///
/// # 検証項目
/// - メールアドレス形式の正当性
/// - パスワード強度（最低6文字、大文字・小文字・数字を含む）
/// - 電話番号形式（日本の電話番号形式）
/// - 必須フィールドの存在確認
/// - 性別の有効性（指定された場合）
fn validate_user_signup_request(req: &UserSignupRequest) -> Result<(), String> {
    // メールアドレスの検証
    if req.email.trim().is_empty() {
        return Err("メールアドレスは必須です".to_string());
    }
    
    if !is_valid_email(&req.email) {
        return Err("有効なメールアドレス形式を入力してください".to_string());
    }
    
    // パスワードの検証
    if req.password.len() < 6 {
        return Err("パスワードは6文字以上である必要があります".to_string());
    }
    
    if !is_strong_password(&req.password) {
        return Err("パスワードは大文字、小文字、数字を含む必要があります".to_string());
    }
    
    // 電話番号の検証
    if req.phone_number.trim().is_empty() {
        return Err("電話番号は必須です".to_string());
    }
    
    if !is_valid_phone_number(&req.phone_number) {
        return Err("有効な電話番号形式を入力してください（例：090-1234-5678）".to_string());
    }
    
    // 氏名の検証
    if req.full_name.trim().is_empty() {
        return Err("氏名は必須です".to_string());
    }
    
    if req.full_name.trim().len() < 2 {
        return Err("氏名は2文字以上で入力してください".to_string());
    }
    
    // 住所の検証
    if req.address.trim().is_empty() {
        return Err("住所は必須です".to_string());
    }
    
    if req.address.trim().len() < 5 {
        return Err("住所は5文字以上で入力してください".to_string());
    }
    
    // 性別の検証（任意フィールド）
    if let Some(gender) = &req.gender {
        if !["male", "female", "other"].contains(&gender.as_str()) {
            return Err("性別は 'male', 'female', 'other' のいずれかを指定してください".to_string());
        }
    }
    
    Ok(())
}

/// オーナー登録リクエストデータの検証
///
/// # 検証項目
/// - ユーザー登録と同様の基本項目
/// - 登録者タイプ（individual/corporate）の有効性
/// - 郵便番号形式の正当性（日本の郵便番号形式）
/// - 事業者固有の必須フィールド
fn validate_owner_signup_request(req: &OwnerSignupRequest) -> Result<(), String> {
    // 基本的な検証（ユーザー登録と同様）
    if req.email.trim().is_empty() {
        return Err("メールアドレスは必須です".to_string());
    }
    
    if !is_valid_email(&req.email) {
        return Err("有効なメールアドレス形式を入力してください".to_string());
    }
    
    if req.password.len() < 6 {
        return Err("パスワードは6文字以上である必要があります".to_string());
    }
    
    if !is_strong_password(&req.password) {
        return Err("パスワードは大文字、小文字、数字を含む必要があります".to_string());
    }
    
    if req.phone_number.trim().is_empty() {
        return Err("電話番号は必須です".to_string());
    }
    
    if !is_valid_phone_number(&req.phone_number) {
        return Err("有効な電話番号形式を入力してください（例：090-1234-5678）".to_string());
    }
    
    if req.full_name.trim().is_empty() {
        return Err("氏名は必須です".to_string());
    }
    
    if req.full_name.trim().len() < 2 {
        return Err("氏名は2文字以上で入力してください".to_string());
    }
    
    if req.address.trim().is_empty() {
        return Err("住所は必須です".to_string());
    }
    
    if req.address.trim().len() < 5 {
        return Err("住所は5文字以上で入力してください".to_string());
    }
    
    // オーナー固有の検証
    if req.registrant_type.trim().is_empty() {
        return Err("登録者タイプは必須です".to_string());
    }
    
    if !["individual", "corporate"].contains(&req.registrant_type.as_str()) {
        return Err("登録者タイプは 'individual'（個人）または 'corporate'（法人）を指定してください".to_string());
    }
    
    if req.postal_code.trim().is_empty() {
        return Err("郵便番号は必須です".to_string());
    }
    
    if !is_valid_postal_code(&req.postal_code) {
        return Err("有効な郵便番号形式を入力してください（例：123-4567）".to_string());
    }
    
    // 性別の検証（任意フィールド）
    if let Some(gender) = &req.gender {
        if !["male", "female", "other"].contains(&gender.as_str()) {
            return Err("性別は 'male', 'female', 'other' のいずれかを指定してください".to_string());
        }
    }
    
    Ok(())
}

// ===== 入力値検証ユーティリティ関数 =====

/// メールアドレス形式の検証
/// 
/// 国際的なメールアドレス形式に準拠した正規表現を使用
fn is_valid_email(email: &str) -> bool {
    use regex::Regex;
    let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
    email_regex.is_match(email.trim())
}

/// パスワード強度の検証
/// 
/// # 要件
/// - 最低1つの大文字
/// - 最低1つの小文字  
/// - 最低1つの数字
/// - 最低6文字以上
fn is_strong_password(password: &str) -> bool {
    let has_upper = password.chars().any(|c| c.is_uppercase());
    let has_lower = password.chars().any(|c| c.is_lowercase());
    let has_digit = password.chars().any(|c| c.is_ascii_digit());
    
    has_upper && has_lower && has_digit && password.len() >= 6
}

/// 日本の電話番号形式の検証
/// 
/// # 対応形式
/// - 090-1234-5678
/// - 09012345678  
/// - +81-90-1234-5678
/// - 固定電話（03-1234-5678など）
fn is_valid_phone_number(phone: &str) -> bool {
    use regex::Regex;
    let phone_regex = Regex::new(r"^(\+81[-\s]?|0)([0-9]{1,4}[-\s]?[0-9]{1,4}[-\s]?[0-9]{4})$").unwrap();
    let cleaned_phone = phone.replace("-", "").replace(" ", "");
    
    // 基本的な長さチェック
    if cleaned_phone.len() < 10 || cleaned_phone.len() > 15 {
        return false;
    }
    
    phone_regex.is_match(phone)
}

/// 日本の郵便番号形式の検証
/// 
/// # 対応形式
/// - 123-4567（標準形式）
fn is_valid_postal_code(postal_code: &str) -> bool {
    use regex::Regex;
    let postal_regex = Regex::new(r"^\d{3}-\d{4}$").unwrap();
    postal_regex.is_match(postal_code.trim())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_メールアドレス検証() {
        assert!(is_valid_email("test@example.com"));
        assert!(is_valid_email("user.name+tag@domain.co.jp"));
        assert!(is_valid_email("  test@example.com  ")); // 前後の空白を許可
        assert!(!is_valid_email("invalid-email"));
        assert!(!is_valid_email("@domain.com"));
        assert!(!is_valid_email("user@"));
        assert!(!is_valid_email(""));
    }

    #[test]
    fn test_パスワード強度検証() {
        assert!(is_strong_password("Password123"));
        assert!(is_strong_password("MyPass1"));
        assert!(is_strong_password("Abcdef1"));
        assert!(!is_strong_password("password")); // 大文字なし
        assert!(!is_strong_password("PASSWORD")); // 小文字なし
        assert!(!is_strong_password("12345678")); // 文字なし
        assert!(!is_strong_password("Pass")); // 短すぎる
        assert!(!is_strong_password("Password")); // 数字なし
    }

    #[test]
    fn test_電話番号検証() {
        assert!(is_valid_phone_number("090-1234-5678"));
        assert!(is_valid_phone_number("09012345678"));
        assert!(is_valid_phone_number("03-1234-5678")); // 固定電話
        assert!(is_valid_phone_number("+81-90-1234-5678"));
        assert!(!is_valid_phone_number("123-456")); // 短すぎる
        assert!(!is_valid_phone_number("abcd-efgh")); // 数字以外
        assert!(!is_valid_phone_number("")); // 空文字
    }

    #[test]
    fn test_郵便番号検証() {
        assert!(is_valid_postal_code("123-4567"));
        assert!(is_valid_postal_code("000-0000"));
        assert!(is_valid_postal_code("  123-4567  ")); // 前後の空白を許可
        assert!(!is_valid_postal_code("1234567")); // ハイフンなし
        assert!(!is_valid_postal_code("12-3456")); // 形式違い
        assert!(!is_valid_postal_code("abc-defg")); // 数字以外
        assert!(!is_valid_postal_code("")); // 空文字
    }
}
