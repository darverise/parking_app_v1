use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct UserModel {
    pub user_id: String,               // user_XXXXXXフォーマット
    pub login_id: Uuid,                // ログインID (UUID)
    pub full_name: String,             // ユーザー氏名
    pub phone_number: Option<String>,  // 電話番号
    pub address: String,               // 住所
    pub promotional_email_opt: String, // プロモーションメール受信設定 (0/1)
    pub service_email_opt: String,     // サービスメール受信設定 (0/1)
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

// 公開用ユーザー情報モデル
#[derive(Debug, Serialize, Deserialize)]
pub struct UserPublicModel {
    pub user_id: String,
    pub full_name: String,
    pub email: String,
    pub phone_number: Option<String>,
}

// ユーザー登録リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateUserRequest {
    pub full_name: String,
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub address: String,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
}

// ユーザー情報更新リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateUserRequest {
    pub full_name: Option<String>,
    pub phone_number: Option<String>,
    pub address: Option<String>,
    pub promotional_email_opt: Option<String>,
    pub service_email_opt: Option<String>,
}

// SQL用の新規ユーザーモデル
#[derive(Debug)]
pub struct NewUser {
    pub login_id: Uuid,
    pub full_name: String,
    pub phone_number: Option<String>,
    pub address: String,
    pub promotional_email_opt: String,
    pub service_email_opt: String,
}
