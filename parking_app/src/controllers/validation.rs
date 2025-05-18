use regex::Regex;
use crate::controllers::api_error::ApiError;
use lazy_static::lazy_static;

lazy_static! {
    // Email validation regex
    static ref EMAIL_REGEX: Regex = Regex::new(
        r"^([a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?)@([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6})"
    ).unwrap();

    // Phone number validation regex for Japan
    static ref PHONE_REGEX: Regex = Regex::new(
        r"^(0[0-9]{1,4}-[0-9]{1,4}-[0-9]{4}|0[0-9]{9,10})$"
    ).unwrap();

    // Password strength validation regex
    // At least 8 characters, one uppercase, one lowercase, one digit, one special character
    static ref PASSWORD_REGEX: Regex = Regex::new(
        r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"
    ).unwrap();

    // Postal code validation regex for Japan (XXX-XXXX)
    static ref POSTAL_CODE_REGEX: Regex = Regex::new(
        r"^\d{3}-\d{4}$"
    ).unwrap();
}

/// 入力検証のためのユーティリティ構造体
pub struct Validator;

impl Validator {
    /// メールアドレスを検証する
    pub fn validate_email(email: &str) -> Result<(), ApiError> {
        if email.is_empty() {
            return Err(ApiError::ValidationError("メールアドレスは必須です".into()));
        }
        
        if !EMAIL_REGEX.is_match(email) {
            return Err(ApiError::ValidationError("無効なメールアドレス形式です".into()));
        }
        
        Ok(())
    }
    
    /// 電話番号を検証する
    pub fn validate_phone(phone: &str) -> Result<(), ApiError> {
        if phone.is_empty() {
            return Err(ApiError::ValidationError("電話番号は必須です".into()));
        }
        
        if !PHONE_REGEX.is_match(phone) {
            return Err(ApiError::ValidationError("無効な電話番号形式です (例: 090-1234-5678)".into()));
        }
        
        Ok(())
    }
    
    /// パスワードの強度を検証する
    pub fn validate_password(password: &str) -> Result<(), ApiError> {
        if password.is_empty() {
            return Err(ApiError::ValidationError("パスワードは必須です".into()));
        }
        
        if password.len() < 8 {
            return Err(ApiError::ValidationError("パスワードは8文字以上である必要があります".into()));
        }
        
        // 詳細な検証（大文字、小文字、数字、特殊文字）
        if !PASSWORD_REGEX.is_match(password) {
            return Err(ApiError::ValidationError(
                "パスワードは大文字、小文字、数字、特殊文字をそれぞれ1つ以上含む必要があります".into()
            ));
        }
        
        Ok(())
    }
    
    /// パスワードが一致するか検証する
    pub fn validate_password_match(password: &str, confirm_password: &str) -> Result<(), ApiError> {
        if password != confirm_password {
            return Err(ApiError::ValidationError("パスワードが一致しません".into()));
        }
        
        Ok(())
    }
    
    /// 郵便番号を検証する
    pub fn validate_postal_code(postal_code: &str) -> Result<(), ApiError> {
        if postal_code.is_empty() {
            return Err(ApiError::ValidationError("郵便番号は必須です".into()));
        }
        
        if !POSTAL_CODE_REGEX.is_match(postal_code) {
            return Err(ApiError::ValidationError("無効な郵便番号形式です (例: 123-4567)".into()));
        }
        
        Ok(())
    }
    
    /// 必須フィールドを検証する
    pub fn validate_required(field_name: &str, value: &str) -> Result<(), ApiError> {
        if value.is_empty() {
            return Err(ApiError::ValidationError(format!("{}は必須です", field_name)));
        }
        
        Ok(())
    }
    
    /// 検証コードを検証する
    pub fn validate_verification_code(code: &str) -> Result<(), ApiError> {
        if code.is_empty() {
            return Err(ApiError::ValidationError("検証コードは必須です".into()));
        }
        
        if code.len() != 6 || !code.chars().all(|c| c.is_digit(10)) {
            return Err(ApiError::ValidationError("検証コードは6桁の数字である必要があります".into()));
        }
        
        Ok(())
    }
    
    /// メールアドレスまたは電話番号を検証する
    pub fn validate_email_or_phone(value: &str) -> Result<(), ApiError> {
        if value.contains('@') {
            Self::validate_email(value)
        } else {
            Self::validate_phone(value)
        }
    }
    
    /// ユーザー登録リクエストを検証する
    pub fn validate_register_request(
        email: &str,
        phone: &str,
        password: &str,
        full_name: &str,
        address: &str,
    ) -> Result<(), ApiError> {
        Self::validate_email(email)?;
        Self::validate_phone(phone)?;
        Self::validate_password(password)?;
        Self::validate_required("氏名", full_name)?;
        Self::validate_required("住所", address)?;
        
        Ok(())
    }
}