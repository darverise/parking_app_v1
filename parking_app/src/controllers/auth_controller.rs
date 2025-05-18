use bcrypt::{hash, verify, DEFAULT_COST};
use tracing::{debug, error, info};
use crate::controllers::api_error::ApiError;
use crate::controllers::api_response::{success_response, error_response};
use actix_web::{get, post, web, Responder};
use crate::models::{
    auth_login_model::{
        SignInRequest, RefreshTokenRequest, ChangePasswordRequest, RegisterRequest,
        VerifyCodeRequest, ResendCodeRequest
    },
    auth_user_model::UpdateUserRequest
};
use crate::services::auth_service::AuthService;
use crate::controllers::validation::Validator;
use crate::config::postgresql_database::PostgresDatabase;

/// Authentication controller handling user authentication workflows
/// 
/// This controller provides endpoints for user authentication operations
/// including sign-in, sign-out, token refresh, user management, and registration.

/// Sign in a user with username/email and password
/// 
/// Returns a JWT token and refresh token upon successful authentication
#[post("/signin")]
pub async fn signin(
    db: web::Data<PostgresDatabase>,
    req: web::Json<SignInRequest>,
) -> impl Responder {
    info!("Processing signin request for user: {}", req.email);
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.signin(&req).await {
        Ok(user) => {
            info!("User signed in successfully: {}", req.email);
            // データ付き成功レスポンス
            success_response(user, None, None, None)
        },
        Err(e) => {
            error!("Sign-in failed for {}: {}", req.email, e);
            error_response(401, &e.to_string())
        },
    }
}

/// Sign out the current user
/// 
/// Invalidates the current session
#[post("/signout")]
pub async fn signout(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::TokenClaims>,
) -> impl Responder {
    info!("Processing signout request for user_id: {}", claims.sub);
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.signout(&claims.sub).await {
        Ok(_) => {
            info!("User signed out successfully: {}", claims.sub);
            // データとメッセージ付き成功レスポンス
            success_response(true, None, Some("サインアウトしました"), None)
        },
        Err(e) => {
            error!("Sign-out failed for {}: {}", claims.sub, e);
            error_response(400, &e.to_string())
        },
    }
}

/// Refresh an authentication token using a refresh token
/// 
/// Returns a new JWT token and refresh token
#[post("/refresh-token")]
pub async fn refresh_token(
    db: web::Data<PostgresDatabase>,
    req: web::Json<RefreshTokenRequest>,
) -> impl Responder {
    debug!("Processing refresh token request");
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.refresh_token(&req).await {
        Ok(user) => {
            debug!("Token refreshed successfully");
            // データ付き成功レスポンス
            success_response(user, None, None, None)
        },
        Err(e) => {
            error!("Failed to refresh token: {}", e);
            error_response(400, &e.to_string())
        },
    }
}

/// Get information about the currently authenticated user
/// 
/// Returns user profile data based on the JWT token
#[get("/user")]
pub async fn get_user_info(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::TokenClaims>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    debug!("Getting user info for user_id: {}", claims.sub);
    
    match auth_service.get_user_info(&claims.sub).await {
        Ok(user) => {
            // データとメッセージ付き成功レスポンス
            success_response(user, None, Some("ユーザーが正常に取得されました"), None)
        },
        Err(e) => {
            error!("Failed to get user info: {}", e);
            error_response(404, &e.to_string())
        },
    }
}

/// Update user profile information
/// 
/// Updates user details like name, phone number, and address
#[post("/user/update")]
pub async fn update_user(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::TokenClaims>,
    req: web::Json<UpdateUserRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    info!("Updating user profile for user_id: {}", claims.sub);
    
    match auth_service.update_user(&claims.sub, &req).await {
        Ok(user) => {
            // データ付き成功レスポンス
            success_response(user, None, None, None)
        },
        Err(e) => {
            error!("Failed to update user: {}", e);
            error_response(400, &e.to_string())
        },
    }
}

/// Change user password
/// 
/// Updates the user's password after verifying the old password
#[post("/user/change-password")]
pub async fn change_password(
    db: web::Data<PostgresDatabase>,
    claims: web::ReqData<crate::middlewares::jwt::TokenClaims>,
    req: web::Json<ChangePasswordRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(db.pool().clone());
    info!("Changing password for user_id: {}", claims.sub);
    
    // First, validate the new password
    match Validator::validate_password(&req.new_password) {
        Ok(_) => (),
        Err(e) => {
            return error_response(400, &e.to_string());
        }
    }
    
    match auth_service.change_password(&claims.sub, &req.old_password, &req.new_password).await {
        Ok(_) => {
            // シンプルな成功レスポンス
            success_response(true, None, None, None)
        },
        Err(e) => {
            error!("Failed to change password: {}", e);
            error_response(400, &e.to_string())
        },
    }
}

/// Register a new user
/// 
/// Creates a new user account or owner account
#[post("/register")]
pub async fn register(
    db: web::Data<PostgresDatabase>,
    req: web::Json<RegisterRequest>,
) -> impl Responder {
    info!("Processing registration request for: {}", req.email);
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.register(&req).await {
        Ok(login_id) => {
            info!("User registered successfully: {}", req.email);
            // Generate verification code and send it (mock)
            match auth_service.generate_verification_code(&req.email, crate::models::auth_login_model::VerificationType::Email).await {
                Ok(_) => (),  // In real app, would send verification email here
                Err(e) => error!("Failed to generate verification code: {}", e),
            }
            // カスタムコード付きレスポンス
            success_response(
                serde_json::json!({ "login_id": login_id }),
                Some(201),
                Some("アカウントが作成されました。確認コードをメールで送信しました。"),
                None
            )
        },
        Err(e) => {
            error!("Registration failed for {}: {}", req.email, e);
            match e {
                ApiError::DuplicateError(_) => error_response(409, &e.to_string()),
                ApiError::ValidationError(_) => error_response(400, &e.to_string()),
                _ => error_response(500, &e.to_string()),
            }
        },
    }
}

/// Verify email or phone number using a verification code
/// 
/// Validates the verification code sent to the user
#[post("/verify-code")]
pub async fn verify_code(
    db: web::Data<PostgresDatabase>,
    req: web::Json<VerifyCodeRequest>,
) -> impl Responder {
    info!("Processing verification code for: {}", req.email);
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.verify_code(&req).await {
        Ok(is_valid) => {
            if is_valid {
                // Mark email as verified in real application
                if let Err(e) = auth_service.mark_email_verified(&req.email).await {
                    error!("Failed to mark email as verified: {}", e);
                }
                // シンプルな成功レスポンス
                success_response(true, None, None, None)
            } else {
                error_response(400, "無効な認証コードです")
            }
        },
        Err(e) => {
            error!("Verification failed for {}: {}", req.email, e);
            error_response(400, &e.to_string())
        },
    }
}

/// Resend verification code
/// 
/// Sends a new verification code to the user's email or phone
#[post("/resend-code")]
pub async fn resend_code(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ResendCodeRequest>,
) -> impl Responder {
    info!("Processing resend code request for: {}", req.email);
    let auth_service = AuthService::new(db.pool().clone());
    
    match auth_service.resend_verification_code(&req).await {
        Ok(_) => {
            // シンプルな成功レスポンス
            success_response(true, None, None, None)
        },
        Err(e) => {
            error!("Resend code failed for {}: {}", req.email, e);
            error_response(400, &e.to_string())
        },
    }
}

/// Hash a password
/// 
/// # Arguments
/// * `password` - Plain text password
/// 
/// # Returns
/// Hashed password or error
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

/// Verify a password against a hash
/// 
/// # Arguments
/// * `password` - Plain text password
/// * `hash` - Hashed password
/// 
/// # Returns
/// Whether the password matches
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

/// Mask a password for logging
/// 
/// # Arguments
/// * `password` - Plain text password
/// 
/// # Returns
/// Masked password
pub fn mask_password(password: &str) -> String {
    if password.len() <= 2 {
        return "*".repeat(password.len());
    }
    
    let visible_chars = 2;
    let first_chars = &password[0..visible_chars];
    let masked_part = "*".repeat(password.len() - visible_chars);
    
    format!("{}{}", first_chars, masked_part)
}
