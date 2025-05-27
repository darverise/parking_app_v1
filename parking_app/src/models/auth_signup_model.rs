use chrono::{DateTime, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// Import database models
use crate::models::m_login_model::MLoginModel;
use crate::models::m_owners_model::MOwnersModel;
use crate::models::m_users_model::MUsersModel;

/// Unified signup request that handles both users and owners based on role
#[derive(Debug, Deserialize, Clone)]
pub struct SignupRequest {
    pub email: String,
    pub phone_number: String,
    pub password: String,
    pub full_name: String,
    pub address: String,
    pub role: UserRole, // Determines which model to use
    // Common optional fields
    pub birthday: Option<String>,
    pub gender: Option<String>,
    pub promotional_email_opt_in: Option<bool>,
    pub service_email_opt_in: Option<bool>,
    pub full_name_kana: Option<String>,
    // Owner-specific fields (ignored for users)
    pub registrant_type: Option<String>,
    pub postal_code: Option<String>,
    pub remarks: Option<String>,
}

/// User role enum to determine which database model to use
#[derive(Debug, Deserialize, Serialize, Clone, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum UserRole {
    User,
    Owner,
}

impl UserRole {
    /// Convert to string for database storage (m_login.is_user_owner)
    pub fn to_db_value(&self) -> String {
        match self {
            UserRole::User => "0".to_string(),  // 0: ユーザーの方
            UserRole::Owner => "1".to_string(), // 1: オーナーの方
        }
    }

    /// Create from database value
    pub fn from_db_value(value: &str) -> Result<Self, String> {
        match value {
            "0" => Ok(UserRole::User),
            "1" => Ok(UserRole::Owner),
            _ => Err(format!("Invalid user role value: {}", value)),
        }
    }
}

impl SignupRequest {
    /// Validate signup request based on role
    pub fn validate(&self) -> Result<(), String> {
        // Common validation
        self.validate_common_fields()?;

        // Role-specific validation
        match self.role {
            UserRole::User => self.validate_user_fields(),
            UserRole::Owner => self.validate_owner_fields(),
        }
    }

    /// Create MLoginModel from signup request
    pub fn to_login_model(&self) -> MLoginModel {
        MLoginModel::new(
            Some(Uuid::new_v4().to_string()), // Generate new login_id
            Some(self.email.clone()),
            Some(self.phone_number.clone()),
            Some(self.password.clone()), // Will be hashed before saving
            Some(self.role.to_db_value()),
            None,                                                     // login_token
            None,                                                     // login_token_expiration
            None,                                                     // login_token_issued_datetime
            Some(0),                                                  // login_token_issued_count
            Some("0".to_string()),                                    // login_token_issued_flag
            Some("1".to_string()), // is_login (0:ログイン中・1:ログイン状態解除)
            None,                  // login_datetime
            None,                  // logout_datetime
            Some(0),               // login_failed_count
            None,                  // login_failed_datetime
            Some("0".to_string()), // login_failed_flag
            None,                  // login_failed_reason
            None,                  // login_failed_reason_detail
            None,                  // login_failed_reset_datetime
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()), // created_datetime
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()), // updated_datetime
        )
    }

    /// Create MUsersModel from signup request (only for User role)
    pub fn to_users_model(&self, login_id: &str) -> Result<MUsersModel, String> {
        if self.role != UserRole::User {
            return Err("Cannot create MUsersModel for non-user role".to_string());
        }

        Ok(MUsersModel::new(
            Some(Uuid::new_v4().to_string()), // Generate new user_id
            Some(login_id.to_string()),
            Some(self.full_name.clone()),
            self.phone_number.clone().into(), // Convert to Option<String>
            Some(self.address.clone()),
            Some(self.promotional_email_opt_in.unwrap_or(false).to_string()),
            Some(self.service_email_opt_in.unwrap_or(false).to_string()),
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()),
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()),
        ))
    }

    /// Create MOwnersModel from signup request (only for Owner role)
    pub fn to_owners_model(&self, login_id: &str) -> Result<MOwnersModel, String> {
        if self.role != UserRole::Owner {
            return Err("Cannot create MOwnersModel for non-owner role".to_string());
        }

        let registrant_type = self
            .registrant_type
            .as_ref()
            .ok_or("registrant_type is required for owner signup")?;
        let postal_code = self
            .postal_code
            .as_ref()
            .ok_or("postal_code is required for owner signup")?;

        Ok(MOwnersModel::new(
            Some(Uuid::new_v4().to_string()), // Generate new owner_id
            Some(login_id.to_string()),
            Some(registrant_type.clone()),
            Some(self.full_name.clone()),
            self.full_name_kana.clone(),
            Some(postal_code.clone()),
            Some(self.address.clone()),
            Some(self.phone_number.clone()),
            self.remarks.clone(),
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()),
            Some(Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()),
        ))
    }

    /// Validate common fields for both users and owners
    fn validate_common_fields(&self) -> Result<(), String> {
        // Email validation
        if self.email.trim().is_empty() {
            return Err("メールアドレスは必須です".to_string());
        }
        if self.email.len() > 255 {
            return Err("メールアドレスは255文字以内で入力してください".to_string());
        }
        if !self.is_valid_email() {
            return Err("有効なメールアドレス形式を入力してください".to_string());
        }

        // Password validation
        if self.password.len() < 6 {
            return Err("パスワードは6文字以上である必要があります".to_string());
        }

        // Phone number validation
        if self.phone_number.trim().is_empty() {
            return Err("電話番号は必須です".to_string());
        }
        if self.phone_number.len() > 50 {
            return Err("電話番号は50文字以内で入力してください".to_string());
        }

        // Full name validation
        if self.full_name.trim().is_empty() {
            return Err("氏名は必須です".to_string());
        }
        if self.full_name.len() > 100 {
            return Err("氏名は100文字以内で入力してください".to_string());
        }

        // Address validation
        if self.address.trim().is_empty() {
            return Err("住所は必須です".to_string());
        }
        if self.address.len() > 1000 {
            return Err("住所は1000文字以内で入力してください".to_string());
        }

        // Optional field validations
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

        if let Some(ref birthday) = self.birthday {
            if !self.is_valid_date(birthday) {
                return Err("生年月日は YYYY-MM-DD 形式で入力してください".to_string());
            }
        }

        if let Some(ref full_name_kana) = self.full_name_kana {
            if full_name_kana.len() > 100 {
                return Err("氏名（カナ）は100文字以内で入力してください".to_string());
            }
        }

        Ok(())
    }

    /// Validate user-specific fields
    fn validate_user_fields(&self) -> Result<(), String> {
        // Users don't have additional required fields beyond common ones
        Ok(())
    }

    /// Validate owner-specific fields
    fn validate_owner_fields(&self) -> Result<(), String> {
        // Registrant type validation
        let registrant_type = self
            .registrant_type
            .as_ref()
            .ok_or("登録者タイプは必須です")?;

        if registrant_type.len() > 20 {
            return Err("登録者タイプは20文字以内で指定してください".to_string());
        }
        if !["individual", "corporate"].contains(&registrant_type.as_str()) {
            return Err(
                "登録者タイプは 'individual' または 'corporate' を指定してください".to_string(),
            );
        }

        // Postal code validation
        let postal_code = self.postal_code.as_ref().ok_or("郵便番号は必須です")?;

        if postal_code.len() > 20 {
            return Err("郵便番号は20文字以内で入力してください".to_string());
        }
        if !self.is_valid_postal_code(postal_code) {
            return Err("有効な郵便番号形式を入力してください（例：123-4567）".to_string());
        }

        // Remarks validation
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

    fn is_valid_postal_code(&self, postal_code: &str) -> bool {
        let postal_regex = Regex::new(r"^\d{3}-\d{4}$").unwrap();
        postal_regex.is_match(postal_code)
    }

    fn is_valid_date(&self, date_str: &str) -> bool {
        let date_regex = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
        date_regex.is_match(date_str)
    }
}

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
    pub registrant_type: String, // "individual" or "corporate"
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
    pub user_type: String, // "user" or "owner"
    pub is_verified: bool,
    pub verification_code: Option<String>, // Only included for development/testing
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Email verification request model
#[derive(Debug, Deserialize)]
pub struct EmailVerificationRequest {
    pub email: String,
    pub verification_code: String,
}

/// Email verification response model
#[derive(Debug, Serialize)]
pub struct EmailVerificationResponse {
    pub success: bool,
    pub message: String,
    pub user_id: Option<String>,
    pub is_verified: bool,
}

/// Resend verification code request model
#[derive(Debug, Deserialize)]
pub struct ResendCodeRequest {
    pub email: String,
}

/// Resend verification code response model
#[derive(Debug, Serialize)]
pub struct ResendCodeResponse {
    pub success: bool,
    pub message: String,
    pub code_sent: bool,
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

// Conversion utilities
impl From<SignupRequest> for SignupResponse {
    fn from(req: SignupRequest) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            email: req.email,
            phone_number: req.phone_number,
            full_name: req.full_name,
            user_type: match req.role {
                UserRole::User => "user".to_string(),
                UserRole::Owner => "owner".to_string(),
            },
            is_verified: false,
            verification_code: None,
            access_token: None,
            refresh_token: None,
            created_at: Utc::now(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_unified_signup_validation_user() {
        let user_request = SignupRequest {
            email: "user@example.com".to_string(),
            phone_number: "09012345678".to_string(),
            password: "UserPass123".to_string(),
            full_name: "山田太郎".to_string(),
            address: "東京都渋谷区渋谷1-1-1".to_string(),
            role: UserRole::User,
            birthday: Some("1990-05-15".to_string()),
            gender: Some("male".to_string()),
            promotional_email_opt_in: Some(true),
            service_email_opt_in: Some(false),
            full_name_kana: None,
            registrant_type: None,
            postal_code: None,
            remarks: None,
        };

        assert!(user_request.validate().is_ok());

        // Test conversion to models
        let login_model = user_request.to_login_model();
        assert_eq!(login_model.email, "user@example.com");
        assert_eq!(login_model.is_user_owner, "0");

        let users_model = user_request.to_users_model(&login_model.login_id);
        assert!(users_model.is_ok());

        let owners_model = user_request.to_owners_model(&login_model.login_id);
        assert!(owners_model.is_err()); // Should fail for user role
    }

    #[test]
    fn test_unified_signup_validation_owner() {
        let owner_request = SignupRequest {
            email: "owner@example.com".to_string(),
            phone_number: "09087654321".to_string(),
            password: "OwnerPass123".to_string(),
            full_name: "山田花子".to_string(),
            address: "東京都渋谷区神宮前1-1-1".to_string(),
            role: UserRole::Owner,
            birthday: Some("1985-03-20".to_string()),
            gender: Some("female".to_string()),
            promotional_email_opt_in: Some(true),
            service_email_opt_in: Some(true),
            full_name_kana: Some("ヤマダハナコ".to_string()),
            registrant_type: Some("individual".to_string()),
            postal_code: Some("150-0001".to_string()),
            remarks: Some("駐車場オーナーです".to_string()),
        };

        assert!(owner_request.validate().is_ok());

        // Test conversion to models
        let login_model = owner_request.to_login_model();
        assert_eq!(login_model.email, "owner@example.com");
        assert_eq!(login_model.is_user_owner, "1");

        let owners_model = owner_request.to_owners_model(&login_model.login_id);
        assert!(owners_model.is_ok());

        let users_model = owner_request.to_users_model(&login_model.login_id);
        assert!(users_model.is_err()); // Should fail for owner role
    }

    #[test]
    fn test_role_conversion() {
        assert_eq!(UserRole::User.to_db_value(), "0");
        assert_eq!(UserRole::Owner.to_db_value(), "1");

        assert_eq!(UserRole::from_db_value("0").unwrap(), UserRole::User);
        assert_eq!(UserRole::from_db_value("1").unwrap(), UserRole::Owner);
        assert!(UserRole::from_db_value("2").is_err());
    }

    #[test]
    fn test_user_signup_validation() {
        let valid_request = UserSignupRequest {
            email: "test.user@example.com".to_string(),
            phone_number: "09012345678".to_string(),
            password: "TestPass123!".to_string(),
            full_name: "山田太郎".to_string(),
            address: "東京都渋谷区渋谷1-1-1 渋谷ビル101".to_string(),
            birthday: Some("1990-05-15".to_string()),
            gender: Some("male".to_string()),
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
        };

        assert!(valid_request.validate().is_ok());
    }

    #[test]
    fn test_owner_signup_validation() {
        let valid_request = OwnerSignupRequest {
            email: "owner@example.com".to_string(),
            phone_number: "09087654321".to_string(),
            password: "OwnerPass123".to_string(),
            registrant_type: "individual".to_string(),
            full_name: "山田花子".to_string(),
            full_name_kana: Some("ヤマダハナコ".to_string()),
            postal_code: "150-0001".to_string(),
            address: "東京都渋谷区神宮前1-1-1".to_string(),
            birthday: Some("1985-05-15".to_string()),
            gender: Some("female".to_string()),
            remarks: Some("駐車場オーナーです".to_string()),
            promotional_email_opt_in: Some(true),
            service_email_opt_in: Some(true),
        };

        assert!(valid_request.validate().is_ok());
    }

    #[test]
    fn test_invalid_email() {
        let request = UserSignupRequest {
            email: "invalid-email".to_string(),
            phone_number: "09012345678".to_string(),
            password: "Password123".to_string(),
            full_name: "田中太郎".to_string(),
            address: "東京都渋谷区1-1-1".to_string(),
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
        };

        assert!(request.validate().is_err());
    }

    #[test]
    fn test_field_length_validation() {
        // Test email length limit (255 chars)
        let mut request = UserSignupRequest {
            email: "a".repeat(250) + "@example.com", // Should be valid
            phone_number: "09012345678".to_string(),
            password: "TestPass123!".to_string(),
            full_name: "山田太郎".to_string(),
            address: "東京都渋谷区渋谷1-1-1".to_string(),
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
        };

        assert!(request.validate().is_ok());

        // Test email exceeding 255 chars
        request.email = "a".repeat(250) + "@example.com"; // Over 255 chars
        if request.email.len() > 255 {
            assert!(request.validate().is_err());
        }

        // Test full_name length limit (100 chars)
        request.email = "test@example.com".to_string();
        request.full_name = "あ".repeat(101); // Exceeds 100 chars
        assert!(request.validate().is_err());

        // Test phone_number length limit (50 chars)
        request.full_name = "山田太郎".to_string();
        request.phone_number = "0".repeat(51); // Exceeds 50 chars
        assert!(request.validate().is_err());

        // Test address length limit (1000 chars)
        request.phone_number = "09012345678".to_string();
        request.address = "あ".repeat(1001); // Exceeds 1000 chars
        assert!(request.validate().is_err());
    }

    #[test]
    fn test_owner_field_length_validation() {
        let mut request = OwnerSignupRequest {
            email: "owner@example.com".to_string(),
            phone_number: "09087654321".to_string(),
            password: "OwnerPass123".to_string(),
            registrant_type: "individual".to_string(),
            full_name: "山田花子".to_string(),
            full_name_kana: Some("ヤマダハナコ".to_string()),
            postal_code: "150-0001".to_string(),
            address: "東京都渋谷区神宮前1-1-1".to_string(),
            birthday: Some("1985-05-15".to_string()),
            gender: Some("female".to_string()),
            remarks: Some("駐車場オーナーです".to_string()),
            promotional_email_opt_in: Some(true),
            service_email_opt_in: Some(true),
        };

        assert!(request.validate().is_ok());

        // Test registrant_type length limit (20 chars)
        request.registrant_type = "a".repeat(21); // Exceeds 20 chars
        assert!(request.validate().is_err());

        // Test postal_code length limit (20 chars)
        request.registrant_type = "individual".to_string();
        request.postal_code = "1".repeat(21); // Exceeds 20 chars
        assert!(request.validate().is_err());
    }

    /// Tests for SignupRequest validation and conversion
    /// These tests cover both user and owner signup scenarios, ensuring that the validation logic works correctly for different roles and that the conversion to database models is functioning as expected.

    #[test]
    fn test_signup_request_user_valid() {
        let req = SignupRequest {
            email: "user1@example.com".to_string(),
            phone_number: "08012345678".to_string(),
            password: "password123".to_string(),
            full_name: "テストユーザー".to_string(),
            address: "東京都千代田区1-1-1".to_string(),
            role: UserRole::User,
            birthday: Some("2000-01-01".to_string()),
            gender: Some("male".to_string()),
            promotional_email_opt_in: Some(true),
            service_email_opt_in: Some(false),
            full_name_kana: Some("テストユーザー".to_string()),
            registrant_type: None,
            postal_code: None,
            remarks: None,
        };
        assert!(req.validate().is_ok());
        let login: MLoginModel = req.to_login_model();
        assert_eq!(login.is_user_owner, "0");
        let user: Result<MUsersModel, String> = req.to_users_model(&login.login_id);
        assert!(user.is_ok());
        let owner: Result<MOwnersModel, String> = req.to_owners_model(&login.login_id);
        assert!(owner.is_err());
    }

    #[test]
    fn test_signup_request_owner_valid() {
        let req = SignupRequest {
            email: "owner1@example.com".to_string(),
            phone_number: "08087654321".to_string(),
            password: "password456".to_string(),
            full_name: "オーナー太郎".to_string(),
            address: "大阪府大阪市1-2-3".to_string(),
            role: UserRole::Owner,
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: Some("オーナータロウ".to_string()),
            registrant_type: Some("corporate".to_string()),
            postal_code: Some("123-4567".to_string()),
            remarks: Some("法人オーナー".to_string()),
        };
        assert!(req.validate().is_ok());
        let login = req.to_login_model();
        assert_eq!(login.is_user_owner, "1");
        let owner = req.to_owners_model(&login.login_id);
        assert!(owner.is_ok());
        let user = req.to_users_model(&login.login_id);
        assert!(user.is_err());
    }

    #[test]
    fn test_signup_request_user_invalid_email() {
        let mut req = SignupRequest {
            email: "invalid-email".to_string(),
            phone_number: "08012345678".to_string(),
            password: "password123".to_string(),
            full_name: "テストユーザー".to_string(),
            address: "東京都千代田区1-1-1".to_string(),
            role: UserRole::User,
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
            registrant_type: None,
            postal_code: None,
            remarks: None,
        };
        assert!(req.validate().is_err());
        req.email = "".to_string();
        assert!(req.validate().is_err());
    }

    #[test]
    fn test_signup_request_owner_missing_fields() {
        let req = SignupRequest {
            email: "owner2@example.com".to_string(),
            phone_number: "08087654321".to_string(),
            password: "password456".to_string(),
            full_name: "オーナー花子".to_string(),
            address: "大阪府大阪市1-2-3".to_string(),
            role: UserRole::Owner,
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
            registrant_type: None, // missing
            postal_code: None,     // missing
            remarks: None,
        };
        assert!(req.validate().is_err());
    }

    #[test]
    fn test_signup_request_owner_invalid_postal_code() {
        let req = SignupRequest {
            email: "owner3@example.com".to_string(),
            phone_number: "08087654321".to_string(),
            password: "password456".to_string(),
            full_name: "オーナー三郎".to_string(),
            address: "大阪府大阪市1-2-3".to_string(),
            role: UserRole::Owner,
            birthday: None,
            gender: None,
            promotional_email_opt_in: None,
            service_email_opt_in: None,
            full_name_kana: None,
            registrant_type: Some("individual".to_string()),
            postal_code: Some("1234567".to_string()), // invalid format
            remarks: None,
        };
        assert!(req.validate().is_err());
    }
}
