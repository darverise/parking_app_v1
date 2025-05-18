use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// ユーザー情報（m_usersテーブル）のモデル
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub user_id: String,
    pub login_id: Uuid,
    pub full_name: String,
    pub phone_number: Option<String>,
    pub address: String,
    pub promotional_email_opt: Option<String>,  // 1: 受け取る, 0: 受け取らない
    pub service_email_opt: Option<String>,      // 1: 受け取る, 0: 受け取らない
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

/// 新規ユーザー作成用のモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct NewUser {
    pub login_id: Uuid,
    pub full_name: String,
    pub phone_number: Option<String>,
    pub address: String,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
}

/// ユーザー作成リクエストのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateUserRequest {
    pub email: String,
    pub phone_number: Option<String>,
    pub password: String,
    pub full_name: String,
    pub address: String,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
}

/// ユーザー更新リクエストのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateUserRequest {
    pub full_name: Option<String>,
    pub phone_number: Option<String>,
    pub address: Option<String>,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
}

/// ユーザー情報レスポンスのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub user_id: String,
    pub login_id: Uuid,
    pub email: String,
    pub phone_number: Option<String>,
    pub full_name: String,
    pub address: String,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
}

impl User {
    /// SQLからの結果を新しいUserインスタンスに変換するヘルパーメソッド
    pub fn new(
        user_id: String,
        login_id: Uuid,
        full_name: String,
        phone_number: Option<String>,
        address: String,
        promotional_email_opt: Option<String>,
        service_email_opt: Option<String>,
        created_datetime: Option<DateTime<Utc>>,
        updated_datetime: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            user_id,
            login_id,
            full_name,
            phone_number,
            address,
            promotional_email_opt,
            service_email_opt,
            created_datetime,
            updated_datetime,
        }
    }
}