use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct LoginModel {
    pub login_id: Uuid,
    pub email: String,
    pub phone_number: String,
    pub pass_word: String,
    pub is_user_owner: String,
    pub login_token: Option<String>,
    pub login_token_expiration: Option<DateTime<Utc>>,
    pub login_token_issued_datetime: Option<DateTime<Utc>>,
    pub login_token_issued_count: i32,
    pub login_token_issued_flag: String,
    pub is_login: String,
    pub login_datetime: Option<DateTime<Utc>>,
    pub logout_datetime: Option<DateTime<Utc>>,
    pub login_failed_count: i32,
    pub login_failed_datetime: Option<DateTime<Utc>>,
    pub login_failed_flag: String,
    pub login_failed_reason: Option<String>,
    pub login_failed_reason_detail: Option<String>,
    pub login_failed_reset_datetime: Option<DateTime<Utc>>,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SignInRequest {
    pub email: String,
    pub password: String,
    pub is_user_owner: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
    pub is_user_owner: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginResponse {
    pub auth_token: String,
    pub user_id: String,
    pub email: String,
    pub username: String,
    pub phone_number: String,
    pub is_owner: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshTokenResponse {
    pub token: String,
    pub refresh_token: String,
    pub token_expires_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChangePasswordRequest {
    pub current_password: String,
    pub new_password: String,
}

// 新規ログインアカウント用モデル
#[derive(Debug)]
pub struct NewLogin {
    pub email: String,
    pub phone_number: String,
    pub pass_word: String,
    pub is_user_owner: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateLoginRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub is_user_owner: String,
}

impl LoginModel {
    pub fn new(email: String, phone_number: String, password: String, is_owner: bool) -> Self {
        let now = Utc::now();
        Self {
            login_id: Uuid::new_v4(),
            email,
            phone_number,
            pass_word: password, // 実際の保存前にハッシュ化する必要あり
            is_user_owner: if is_owner { "1".to_string() } else { "0".to_string() },
            login_token: None,
            login_token_expiration: None,
            login_token_issued_datetime: None,
            login_token_issued_count: 0,
            login_token_issued_flag: "0".to_string(),
            is_login: "0".to_string(),
            login_datetime: None,
            logout_datetime: None,
            login_failed_count: 0,
            login_failed_datetime: None,
            login_failed_flag: "0".to_string(),
            login_failed_reason: None,
            login_failed_reason_detail: None,
            login_failed_reset_datetime: None,
            created_datetime: now,
            updated_datetime: now,
        }
    }

    pub fn is_owner(&self) -> bool {
        self.is_user_owner == "1"
    }

    pub fn update_login_token(&mut self, token: String, expiration: DateTime<Utc>) {
        let now = Utc::now();
        self.login_token = Some(token);
        self.login_token_expiration = Some(expiration);
        self.login_token_issued_datetime = Some(now);
        self.login_token_issued_count += 1;
        self.login_token_issued_flag = "1".to_string();
        self.updated_datetime = now;
    }

    pub fn login_success(&mut self) {
        let now = Utc::now();
        self.is_login = "1".to_string();
        self.login_datetime = Some(now);
        self.login_failed_flag = "0".to_string();
        self.updated_datetime = now;
    }

    pub fn login_failure(&mut self, reason: &str, detail: Option<&str>) {
        let now = Utc::now();
        self.login_failed_count += 1;
        self.login_failed_datetime = Some(now);
        self.login_failed_flag = "1".to_string();
        self.login_failed_reason = Some(reason.to_string());
        self.login_failed_reason_detail = detail.map(|s| s.to_string());
        self.updated_datetime = now;
    }

    pub fn logout(&mut self) {
        let now = Utc::now();
        self.is_login = "0".to_string();
        self.logout_datetime = Some(now);
        self.login_token = None;
        self.updated_datetime = now;
    }

    pub fn reset_failed_login(&mut self) {
        let now = Utc::now();
        self.login_failed_count = 0;
        self.login_failed_flag = "0".to_string();
        self.login_failed_reset_datetime = Some(now);
        self.updated_datetime = now;
    }
    
    pub fn is_account_locked(&self) -> bool {
        if self.login_failed_flag != "1" {
            return false;
        }
        
        // 5回以上のログイン失敗かつ30分以内の場合はロック
        if self.login_failed_count >= 5 {
            if let Some(failed_time) = self.login_failed_datetime {
                let thirty_mins_ago = Utc::now() - chrono::Duration::minutes(30);
                return failed_time > thirty_mins_ago;
            }
        }
        false
    }
}