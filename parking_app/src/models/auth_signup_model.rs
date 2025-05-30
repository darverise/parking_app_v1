use chrono::{DateTime, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};


// Import database models
use crate::models::m_login_model::MLoginModel;
use crate::models::m_owners_model::MOwnersModel;
use crate::models::m_users_model::MUsersModel;
/// User signup request model - matches Flutter AuthSignupModel
#[derive(Debug, Deserialize, Clone)]
pub struct UserSignupRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub full_name: String,
    pub address: String,
    pub birthday: Option<String>,
    pub gender: Option<String>,
    pub promotional_email_opt_in: Option<bool>,
    pub service_email_opt_in: Option<bool>,
    pub full_name_kana: Option<String>,
}

/// Owner signup request model - matches Flutter AuthSignupModel for owners
#[derive(Debug, Deserialize, Clone)]
pub struct OwnerSignupRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub registrant_type: String,
    pub full_name: String,
    pub full_name_kana: Option<String>,
    pub postal_code: String,
    pub address: String,
    pub birthday: Option<String>,
    pub gender: Option<String>,
    pub remarks: Option<String>,
    pub promotional_email_opt_in: Option<bool>,
    pub service_email_opt_in: Option<bool>,
}

/// Unified signup response model for both users and owners
#[derive(Debug, Serialize, Clone)]
pub struct SignupResponse {
    pub id: String,
    pub email: String,
    pub phone_number: String,
    pub full_name: String,
    pub user_type: String,
    pub is_verified: bool,
    pub verification_code: Option<String>,
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
    pub created_at: DateTime<Utc>,
}

impl SignupResponse {
    /// 从用户数据库模型创建响应对象
    ///
    /// # Arguments
    /// * `login` - 登录信息模型
    /// * `user` - 用户信息模型
    /// * `verification_code` - 可选的验证码
    /// * `access_token` - 可选的访问令牌
    /// * `refresh_token` - 可选的刷新令牌
    pub fn from_user(
        login: &MLoginModel,
        user: &MUsersModel,
        verification_code: Option<String>,
        access_token: Option<String>,
        refresh_token: Option<String>,
    ) -> Self {
        Self {
            id: user.user_id.clone(),
            email: login.email.clone(),
            phone_number: Self::get_phone_number(&login.phone_number, &user.phone_number),
            full_name: user.full_name.clone(),
            user_type: "user".to_string(),
            is_verified: Self::is_account_verified(&login.login_token_issued_flag),
            verification_code,
            access_token,
            refresh_token,
            created_at: Self::parse_created_datetime(&login.created_datetime),
        }
    }

    /// 从车主数据库模型创建响应对象
    ///
    /// # Arguments
    /// * `login` - 登录信息模型
    /// * `owner` - 车主信息模型
    /// * `verification_code` - 可选的验证码
    /// * `access_token` - 可选的访问令牌
    /// * `refresh_token` - 可选的刷新令牌
    pub fn from_owner(
        login: &MLoginModel,
        owner: &MOwnersModel,
        verification_code: Option<String>,
        access_token: Option<String>,
        refresh_token: Option<String>,
    ) -> Self {
        Self {
            id: owner.owner_id.clone(),
            email: login.email.clone(),
            phone_number: owner.phone_number.clone(),
            full_name: owner.full_name.clone(),
            user_type: "owner".to_string(),
            is_verified: Self::is_account_verified(&login.login_token_issued_flag),
            verification_code,
            access_token,
            refresh_token,
            created_at: Self::parse_created_datetime(&login.created_datetime),
        }
    }

    /// 获取电话号码，优先使用login表中的数据，如果为空则使用用户表的数据
    fn get_phone_number(login_phone: &str, user_phone: &Option<String>) -> String {
        if !login_phone.trim().is_empty() {
            login_phone.to_string()
        } else {
            user_phone.as_ref().unwrap_or(&String::new()).clone()
        }
    }

    /// 判断账户是否已验证
    /// login_token_issued_flag为"1"表示已验证
    fn is_account_verified(flag: &str) -> bool {
        flag == "1"
    }

    /// 安全解析创建时间，如果解析失败则使用当前时间
    fn parse_created_datetime(datetime_str: &Option<String>) -> DateTime<Utc> {
        datetime_str
            .as_ref()
            .and_then(|dt| {
                // 尝试多种时间格式解析
                DateTime::parse_from_rfc3339(dt)
                    .map(|dt| dt.with_timezone(&Utc))
                    .or_else(|_| {
                        // 如果RFC3339格式失败，尝试其他常见格式
                        chrono::NaiveDateTime::parse_from_str(dt, "%Y-%m-%d %H:%M:%S")
                            .map(|ndt| ndt.and_utc())
                    })
                    .ok()
            })
            .unwrap_or_else(Utc::now)
    }
}

/// 便捷的From trait实现，用于快速转换（不带token）
impl From<(&MLoginModel, &MUsersModel)> for SignupResponse {
    fn from((login, user): (&MLoginModel, &MUsersModel)) -> Self {
        SignupResponse::from_user(login, user, None, None, None)
    }
}

impl From<(&MLoginModel, &MOwnersModel)> for SignupResponse {
    fn from((login, owner): (&MLoginModel, &MOwnersModel)) -> Self {
        SignupResponse::from_owner(login, owner, None, None, None)
    }
}

/// Password reset request model
#[derive(Debug, Deserialize)]
pub struct PasswordResetRequest {
    pub email: String,
}

/// Password reset verification model
#[derive(Debug, Deserialize)]
pub struct PasswordResetVerification {
    pub email: String,
    pub reset_code: String,
}

/// Complete password reset model
#[derive(Debug, Deserialize)]
pub struct CompletePasswordReset {
    pub email: String,
    pub reset_code: String,
    pub new_password: String,
}


// Implementation for validation and conversion
impl UserSignupRequest {
    /// Validate user signup request data according to database schema constraints
    pub fn validate(&self) -> Result<(), String> {
        // Email validation - VARCHAR(255) in m_login
        if self.email.trim().is_empty() {
            return Err("メールアドレスは必須です".to_string());
        }

        if self.email.len() > 255 {
            return Err("メールアドレスは255文字以内で入力してください".to_string());
        }

        if !self.is_valid_email() {
            return Err("有効なメールアドレス形式を入力してください".to_string());
        }

        // Password validation - TEXT in m_login (will be hashed)
        if self.password.len() < 6 {
            return Err("パスワードは6文字以上である必要があります".to_string());
        }

        // Phone number validation - VARCHAR(50) in m_login and m_users
        if self.phone_number.trim().is_empty() {
            return Err("電話番号は必須です".to_string());
        }

        if self.phone_number.len() > 50 {
            return Err("電話番号は50文字以内で入力してください".to_string());
        }

        // Full name validation - VARCHAR(100) in m_users
        if self.full_name.trim().is_empty() {
            return Err("氏名は必須です".to_string());
        }

        if self.full_name.len() > 100 {
            return Err("氏名は100文字以内で入力してください".to_string());
        }

        // Address validation - TEXT in m_users (no specific length limit but reasonable check)
        if self.address.trim().is_empty() {
            return Err("住所は必須です".to_string());
        }

        if self.address.len() > 1000 {
            return Err("住所は1000文字以内で入力してください".to_string());
        }

        // Gender validation - VARCHAR(10) in m_users
        if let Some(ref gender) = self.gender {
            if gender.len() > 10 {
                return Err("性別は10文字以内で指定してください".to_string());
            }
            if !["male", "female", "other"].contains(&gender.as_str()) {
                return Err(
                    "性別は 'male', 'female', 'other' のいずれかを指定してください".to_string(),
                );
            }
        }

        // Birthday validation (DATE format)
        if let Some(ref birthday) = self.birthday {
            if !self.is_valid_date(birthday) {
                return Err("生年月日は YYYY-MM-DD 形式で入力してください".to_string());
            }
        }

        // Full name kana validation (not in DB schema but keep for compatibility)
        if let Some(ref full_name_kana) = self.full_name_kana {
            if full_name_kana.len() > 100 {
                return Err("氏名（カナ）は100文字以内で入力してください".to_string());
            }
        }

        Ok(())
    }

    /// Convert promotional_email_opt_in to DB string ("1" or "0")
    pub fn promotional_email_opt_str(&self) -> String {
        if self.promotional_email_opt_in.unwrap_or(false) {
            "1".to_string()
        } else {
            "0".to_string()
        }
    }

    /// Convert service_email_opt_in to DB string ("1" or "0")
    pub fn service_email_opt_str(&self) -> String {
        if self.service_email_opt_in.unwrap_or(false) {
            "1".to_string()
        } else {
            "0".to_string()
        }
    }

    fn is_valid_email(&self) -> bool {
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        email_regex.is_match(&self.email)
    }

    fn is_valid_date(&self, date_str: &str) -> bool {
        let date_regex = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
        date_regex.is_match(date_str)
    }
}

impl OwnerSignupRequest {
    /// Validate owner signup request data according to database schema constraints
    pub fn validate(&self) -> Result<(), String> {
        // Email validation - VARCHAR(255) in m_login
        if self.email.trim().is_empty() {
            return Err("メールアドレスは必須です".to_string());
        }

        if self.email.len() > 255 {
            return Err("メールアドレスは255文字以内で入力してください".to_string());
        }

        if !self.is_valid_email() {
            return Err("有効なメールアドレス形式を入力してください".to_string());
        }

        // Password validation - TEXT in m_login (will be hashed)
        if self.password.len() < 6 {
            return Err("パスワードは6文字以上である必要があります".to_string());
        }

        // Phone number validation - VARCHAR(50) in m_login and m_owners
        if self.phone_number.trim().is_empty() {
            return Err("電話番号は必須です".to_string());
        }

        if self.phone_number.len() > 50 {
            return Err("電話番号は50文字以内で入力してください".to_string());
        }

        // Full name validation - VARCHAR(100) in m_owners
        if self.full_name.trim().is_empty() {
            return Err("氏名は必須です".to_string());
        }

        if self.full_name.len() > 100 {
            return Err("氏名は100文字以内で入力してください".to_string());
        }

        // Full name kana validation - VARCHAR(100) in m_owners
        if let Some(ref full_name_kana) = self.full_name_kana {
            if full_name_kana.len() > 100 {
                return Err("氏名（カナ）は100文字以内で入力してください".to_string());
            }
        }

        // Address validation - TEXT in m_owners
        if self.address.trim().is_empty() {
            return Err("住所は必須です".to_string());
        }

        if self.address.len() > 1000 {
            return Err("住所は1000文字以内で入力してください".to_string());
        }

        // Registrant type validation - VARCHAR(20) in m_owners
        if self.registrant_type.trim().is_empty() {
            return Err("登録者タイプは必須です".to_string());
        }

        if self.registrant_type.len() > 20 {
            return Err("登録者タイプは20文字以内で指定してください".to_string());
        }

        if !["individual", "corporate"].contains(&self.registrant_type.as_str()) {
            return Err(
                "登録者タイプは 'individual' または 'corporate' を指定してください".to_string(),
            );
        }

        // Postal code validation - VARCHAR(20) in m_owners
        if self.postal_code.trim().is_empty() {
            return Err("郵便番号は必須です".to_string());
        }

        if self.postal_code.len() > 20 {
            return Err("郵便番号は20文字以内で入力してください".to_string());
        }

        if !self.is_valid_postal_code() {
            return Err("有効な郵便番号形式を入力してください（例：123-4567）".to_string());
        }

        // Gender validation - VARCHAR(10) in m_owners
        if let Some(ref gender) = self.gender {
            if gender.len() > 10 {
                return Err("性別は10文字以内で指定してください".to_string());
            }
            if !["male", "female", "other"].contains(&gender.as_str()) {
                return Err(
                    "性別は 'male', 'female', 'other' のいずれかを指定してください".to_string(),
                );
            }
        }

        // Birthday validation (DATE format)
        if let Some(ref birthday) = self.birthday {
            if !self.is_valid_date(birthday) {
                return Err("生年月日は YYYY-MM-DD 形式で入力してください".to_string());
            }
        }

        // Remarks validation - TEXT in m_owners
        if let Some(ref remarks) = self.remarks {
            if remarks.len() > 1000 {
                return Err("備考は1000文字以内で入力してください".to_string());
            }
        }

        Ok(())
    }

    fn is_valid_email(&self) -> bool {
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        email_regex.is_match(&self.email)
    }

    fn is_valid_postal_code(&self) -> bool {
        let postal_regex = Regex::new(r"^\d{3}-\d{4}$").unwrap();
        postal_regex.is_match(&self.postal_code)
    }

    fn is_valid_date(&self, date_str: &str) -> bool {
        let date_regex = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
        date_regex.is_match(date_str)
    }
}