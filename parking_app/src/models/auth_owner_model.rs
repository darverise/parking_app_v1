use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerModel {
    pub owner_id: String,               // owner_XXXXXXフォーマット
    pub login_id: Uuid,                 // ログインID (UUID)
    pub registrant_type: String,        // 登録者種別（個人 or 法人）
    pub full_name: String,              // オーナー氏名
    pub full_name_kana: Option<String>, // オーナー氏名（カナ）
    pub postal_code: String,            // 郵便番号
    pub address: String,                // 住所
    pub phone_number: String,           // 電話番号
    pub remarks: Option<String>,        // 備考
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

// 公開用オーナー情報モデル
#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerPublicModel {
    pub owner_id: String,
    pub full_name: String,
    pub email: String,
    pub phone_number: String,
    pub registrant_type: String,
}

// オーナー登録リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateOwnerRequest {
    pub email: String,
    pub password: String,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub phone_number: String,
    pub remarks: Option<String>,
}

// オーナー情報更新リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateOwnerRequest {
    pub full_name: Option<String>,
    pub full_name_kana: Option<String>,
    pub postal_code: Option<String>,
    pub address: Option<String>,
    pub phone_number: Option<String>,
    pub remarks: Option<String>,
}

// SQL用の新規オーナーモデル
#[derive(Debug)]
pub struct NewOwner {
    pub login_id: Uuid,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub phone_number: String,
    pub remarks: Option<String>,
}
