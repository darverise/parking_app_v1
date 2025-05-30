use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Deserialize)]
pub struct SigninRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct SigninResponse {
    pub id: String,
    pub email: String,
    pub user_type: String,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct RefreshTokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateUserRequest {
    pub full_name: Option<String>,
    pub phone_number: Option<String>,
    pub address: Option<String>,
    pub birthday: Option<String>,
    pub gender: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct UserInfoResponse {
    pub id: String,
    pub email: String,
    pub full_name: String,
    pub phone_number: String,
    pub user_type: String,
    pub address: Option<String>,
    pub birthday: Option<String>,
    pub gender: Option<String>,
    pub created_at: String,
}

// 数据库记录结构 - 匹配实际数据库架构
#[derive(Debug, sqlx::FromRow)]
pub struct LoginRecord {
    pub login_id: Uuid,
    pub email: String,
    pub phone_number: String,
    pub pass_word: String,  // 注意：数据库中是pass_word不是password
    pub is_user_owner: String, // 数据库中定义为VARCHAR(1)
    pub login_token: Option<String>,
    pub login_token_expiration: Option<DateTime<Utc>>,
    pub is_login: String,
    pub login_datetime: Option<DateTime<Utc>>,
    pub logout_datetime: Option<DateTime<Utc>>,
    pub login_failed_count: i32,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct UserRecord {
    pub user_id: String,
    pub login_id: Uuid,
    pub full_name: String,
    pub birthday: Option<chrono::NaiveDate>,
    pub gender: Option<String>,
    pub phone_number: String,
    pub address: String,
    pub promotional_email_opt: String,
    pub service_email_opt: String,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct OwnerRecord {
    pub owner_id: String,
    pub login_id: Uuid,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub birthday: Option<chrono::NaiveDate>,
    pub gender: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub phone_number: String,
    pub remarks: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}