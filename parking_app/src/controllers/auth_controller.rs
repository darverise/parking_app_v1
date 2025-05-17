use bcrypt::{hash, verify, DEFAULT_COST};
use tracing::{debug, error};
use crate::controllers::api_error::ApiError;
use actix_web::{get, post, web, HttpResponse, Responder};
use crate::models::{auth_login_model::{SignInRequest, RefreshTokenRequest, ChangePasswordRequest}, auth_user_model::UpdateUserRequest};
use crate::services::auth_service::AuthService;
use crate::config::postgresql_database::PostgresDatabase;
use serde_json::json;

#[post("/signin")]
pub async fn signin(
    db: web::Data<PostgresDatabase>,
    req: web::Json<SignInRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    match auth_service.signin(&req.username, &req.password).await {
        Ok(user) => HttpResponse::Ok().json(json!({
            "code": 200,
            "data": user,
            "message": "Sign-in successful"
        })),
        Err(e) => HttpResponse::Unauthorized().json(json!({
            "code": 401,
            "message": e.to_string()
        })),
    }
}

#[post("/signout")]
pub async fn signout() -> impl Responder {
    HttpResponse::Ok().json(json!({
        "code": 200,
        "message": "Sign-out successful"
    }))
}

#[post("/refresh-token")]
pub async fn refresh_token(
    db: web::Data<PostgresDatabase>,
    req: web::Json<RefreshTokenRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    match auth_service.refresh_token(&req.refresh_token).await {
        Ok(user) => HttpResponse::Ok().json(json!({
            "code": 200,
            "data": user,
            "message": "Token refreshed"
        })),
        Err(e) => HttpResponse::BadRequest().json(json!({
            "code": 400,
            "message": e.to_string()
        })),
    }
}

#[get("/user")]
pub async fn get_user_info(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::Claims>, // 更新引用路径
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    match auth_service.get_user_info(&claims.sub).await {
        Ok(user) => HttpResponse::Ok().json(json!({
            "code": 200,
            "data": user,
            "message": "User info retrieved"
        })),
        Err(e) => HttpResponse::NotFound().json(json!({
            "code": 404,
            "message": e.to_string()
        })),
    }
}

#[post("/user/update")]
pub async fn update_user(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::Claims>, // 更新引用路径
    req: web::Json<UpdateUserRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    match auth_service.update_user(&claims.sub, &req).await {
        Ok(user) => HttpResponse::Ok().json(json!({
            "code": 200,
            "data": user,
            "message": "User updated"
        })),
        Err(e) => HttpResponse::BadRequest().json(json!({
            "code": 400,
            "message": e.to_string()
        })),
    }
}

#[post("/user/change-password")]
pub async fn change_password(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::Claims>, // 更新引用路径
    req: web::Json<ChangePasswordRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    match auth_service.change_password(&claims.sub, &req.old_password, &req.new_password).await {
        Ok(_) => HttpResponse::Ok().json(json!({
            "code": 200,
            "message": "Password changed"
        })),
        Err(e) => HttpResponse::BadRequest().json(json!({
            "code": 400,
            "message": e.to_string()
        })),
    }
}

// パスワードをハッシュ化する
pub fn hash_password(password: &str) -> Result<String, ApiError> {
    debug!("Hashing password");
    
    if password.is_empty() {
        return Err(ApiError::ValidationError("パスワードが空です".into()));
    }
    
    match hash(password, DEFAULT_COST) {
        Ok(hashed) => Ok(hashed),
        Err(e) => {
            error!("Failed to hash password: {}", e);
            Err(ApiError::InternalServerError)
        }
    }
}

// パスワードを検証する
pub fn verify_password(password: &str, hash: &str) -> Result<bool, ApiError> {
    debug!("Verifying password");
    
    if password.is_empty() || hash.is_empty() {
        return Err(ApiError::ValidationError("パスワードまたはハッシュが空です".into()));
    }
    
    match verify(password, hash) {
        Ok(valid) => Ok(valid),
        Err(e) => {
            error!("Failed to verify password: {}", e);
            Err(ApiError::InternalServerError)
        }
    }
}

// パスワードの強度を検証する
pub fn validate_password(password: &str) -> Result<(), ApiError> {
    debug!("Validating password strength");
    
    if password.len() < 8 {
        return Err(ApiError::ValidationError("パスワードは8文字以上である必要があります".into()));
    }
    
    let has_uppercase = password.chars().any(|c| c.is_uppercase());
    let has_lowercase = password.chars().any(|c| c.is_lowercase());
    let has_digit = password.chars().any(|c| c.is_digit(10));
    let has_special = password.chars().any(|c| !c.is_alphanumeric());
    
    if !has_uppercase || !has_lowercase || !has_digit || !has_special {
        return Err(ApiError::ValidationError(
            "パスワードは大文字、小文字、数字、特殊文字をそれぞれ1つ以上含む必要があります".into()
        ));
    }
    
    Ok(())
}

// パスワードをマスクする（ログ出力用）
pub fn mask_password(password: &str) -> String {
    if password.len() <= 2 {
        return "*".repeat(password.len());
    }
    
    let visible_chars = 2;
    let first_chars = &password[0..visible_chars];
    let masked_part = "*".repeat(password.len() - visible_chars);
    
    format!("{}{}", first_chars, masked_part)
}
