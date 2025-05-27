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

    // モデルの検証メソッドを使用した入力データの検証
    if let Err(validation_error) = request_data.validate() {
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
#[post("/owner")]
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

    // モデルの検証メソッドを使用した入力データの検証
    if let Err(validation_error) = request_data.validate() {
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
