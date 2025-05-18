use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 駐車場オーナー情報（m_ownersテーブル）のモデル
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Owner {
    pub owner_id: String,
    pub login_id: Uuid,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub phone_number: String,
    pub remarks: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

/// 新規オーナー作成用のモデル
#[derive(Debug, Serialize, Deserialize)]
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

/// オーナー作成リクエストのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateOwnerRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub remarks: Option<String>,
}

/// オーナー更新リクエストのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateOwnerRequest {
    pub full_name: Option<String>,
    pub full_name_kana: Option<String>,
    pub postal_code: Option<String>,
    pub address: Option<String>,
    pub phone_number: Option<String>,
    pub remarks: Option<String>,
}

/// オーナー情報レスポンスのためのモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerResponse {
    pub owner_id: String,
    pub login_id: Uuid,
    pub email: String,
    pub phone_number: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub registrant_type: String,
    pub remarks: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
}

impl Owner {
    /// SQLからの結果を新しいOwnerインスタンスに変換するヘルパーメソッド
    pub fn new(
        owner_id: String,
        login_id: Uuid,
        registrant_type: String,
        full_name: String,
        full_name_kana: Option<String>,
        postal_code: String,
        address: String,
        phone_number: String,
        remarks: Option<String>,
        created_datetime: Option<DateTime<Utc>>,
        updated_datetime: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            owner_id,
            login_id,
            registrant_type,
            full_name,
            full_name_kana,
            postal_code,
            address,
            phone_number,
            remarks,
            created_datetime,
            updated_datetime,
        }
    }
}