// src/models/mod.rs
use sqlx::FromRow;
use uuid::Uuid;

pub mod auth_login_model;
pub mod auth_owner_model;
pub mod auth_user_model;
pub mod auth_signup_model;
pub mod m_login_model;
pub mod m_users_model;
pub mod m_owners_model;
pub mod auth_model;

// 共通で使用するモデルの再エクスポート
pub use auth_login_model::{
    Login, SignInRequest, RefreshTokenRequest, ChangePasswordRequest, RegisterRequest,
    SignInResponse, VerifyCodeRequest, ResendCodeRequest, VerificationType
};
pub use auth_owner_model::{Owner, CreateOwnerRequest, UpdateOwnerRequest, OwnerResponse};
pub use auth_user_model::{User, CreateUserRequest, UpdateUserRequest, UserResponse};


#[derive(Debug, FromRow)]
pub struct LoginIdRow {
    pub login_id: Uuid,
}

#[derive(Debug, FromRow)]
pub struct UserIdRow {
    pub user_id: String,
}

#[derive(Debug, FromRow)]
pub struct OwnerIdRow {
    pub owner_id: String,
}