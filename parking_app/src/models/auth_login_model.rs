use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// ログイン情報（m_loginテーブル）のモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct Login {
    pub login_id: Uuid,
    pub email: String,
    pub phone_number: String,
    pub pass_word: String,
    pub is_user_owner: String,  // 1: オーナー, 0: 一般ユーザー
    pub login_token: Option<String>,
    pub login_token_expiration: Option<DateTime<Utc>>,
    pub login_token_issued_datetime: Option<DateTime<Utc>>,
    pub login_token_issued_count: i32,
    pub login_token_issued_flag: String,  // 1: 発行済み, 0: 未発行
    pub is_login: String,  // 1: ログイン中, 0: ログインしていない
    pub login_datetime: Option<DateTime<Utc>>,
    pub logout_datetime: Option<DateTime<Utc>>,
    pub login_failed_count: i32,
    pub login_failed_datetime: Option<DateTime<Utc>>,
    pub login_failed_flag: String,  // 1: ログイン失敗, 0: ログイン成功
    pub login_failed_reason: Option<String>,
    pub login_failed_reason_detail: Option<String>,
    pub login_failed_reset_datetime: Option<DateTime<Utc>>,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// 新規ログイン作成用のモデル
#[derive(Debug, Serialize, Deserialize)]
pub struct NewLogin {
    pub email: String,
    pub phone_number: String,
    pub pass_word: String,
    pub is_user_owner: String, // 1: オーナー, 0: 一般ユーザー
}

impl Login {
    /// アカウントがロックされているかどうかを確認する
    /// 
    /// 連続した5回以上のログイン失敗があり、最後の失敗から30分以内の場合、
    /// アカウントはロックされていると判断します。
    pub fn is_account_locked(&self) -> bool {
        // 5回以上のログイン失敗があり、ログイン失敗フラグが設定されている場合
        if self.login_failed_count >= 5 && self.login_failed_flag == "1" {
            if let Some(failed_time) = self.login_failed_datetime {
                let thirty_minutes_ago = Utc::now() - chrono::Duration::minutes(30);
                return failed_time > thirty_minutes_ago;
            }
        }
        false
    }
    
    /// ユーザータイプを取得する (ownerかuserか)
    pub fn is_owner(&self) -> bool {
        self.is_user_owner == "1"
    }
}

/// ログインリクエスト（フロントエンドからのリクエスト）
#[derive(Debug, Serialize, Deserialize)]
pub struct SignInRequest {
    pub email: String,
    pub password: String,
    #[serde(default)]
    pub remember_me: bool,
}

/// ログインレスポンス（フロントエンドへの応答）
#[derive(Debug, Serialize, Deserialize)]
pub struct SignInResponse {
    pub id: Uuid,
    pub email: String,
    pub phone_number: String,
    pub is_owner: bool,
    pub full_name: String,
    pub token: String,
    pub refresh_token: String,
}

/// リフレッシュトークンリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

/// パスワード変更リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

/// 新規ユーザー登録リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub full_name: String,
    pub is_owner: bool,
    // 共通フィールド
    pub address: String,
    // オーナー専用フィールド（オーナーの場合のみ使用）
    pub postal_code: Option<String>,
    pub registrant_type: Option<String>,
    pub full_name_kana: Option<String>,
    pub remarks: Option<String>,
    // 追加オプション
    pub service_email_opt: Option<String>,
    pub promotional_email_opt: Option<String>,
}

/// 検証コード検証リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct VerifyCodeRequest {
    pub email: String,
    pub code: String,
    pub verification_type: VerificationType,
}

/// 検証コード再送リクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ResendCodeRequest {
    pub email: String,
    pub verification_type: VerificationType,
}

/// 検証タイプ
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq, Clone)]
pub enum VerificationType {
    #[serde(rename = "email")]
    Email,
    #[serde(rename = "sms")]
    SMS,
}

/// 汎用的なログインモデル（サービス間の受け渡し用）
#[derive(Debug, Serialize, Deserialize)]
pub struct LoginModel {
    pub email: String,
    pub phone_number: Option<String>,
    pub password: String,
    pub is_owner: bool,
}