use bcrypt::{hash, verify, DEFAULT_COST};
use crate::models::{
    auth_login_model::{
        SignInRequest, RefreshTokenRequest, RegisterRequest,
        SignInResponse, VerifyCodeRequest, ResendCodeRequest, VerificationType
    }, 
    auth_user_model::{UpdateUserRequest},
};
use crate::repositories::auth_repository::AuthRepository;
use crate::middlewares::jwt::{verify_refresh_token, generate_jwt, generate_refresh_token};
use crate::controllers::api_error::ApiError;
use crate::controllers::validation::Validator;
use rand::Rng;  // 使用更新的 rand::Rng 而不是已弃用的 thread_rng
use sqlx::PgPool;
use uuid::Uuid;
use tracing::{debug, error, info, warn};
use chrono::{Utc, Duration};

/// Authentication service responsible for authentication-related business logic
pub struct AuthService {
    repo: AuthRepository,
}

impl AuthService {
    /// Create a new AuthService with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { repo: AuthRepository::new(pool) }
    }

    /// Authenticate a user and generate JWT tokens
    /// 
    /// # Arguments
    /// * `request` - SignInRequest containing email/username and password
    /// 
    /// # Returns
    /// SignInResponse containing user info and authentication tokens
    pub async fn signin(&self, request: &SignInRequest) -> Result<SignInResponse, ApiError> {
        debug!("Authenticating user: {}", request.email);
        
        // Validate input
        Validator::validate_email_or_phone(&request.email)?;
        if request.password.is_empty() {
            return Err(ApiError::ValidationError("パスワードは必須です".into()));
        }
        
        // Get login by email or phone
        let login = if request.email.contains('@') {
            debug!("Looking up user by email: {}", request.email);
            self.repo.get_login_by_email(&request.email).await
                .map_err(|e| {
                    error!("Login lookup failed: {}", e);
                    ApiError::AuthenticationError("ユーザー名またはパスワードが無効です".into())
                })?
        } else {
            debug!("Looking up user by phone: {}", request.email);
            self.repo.get_login_by_phone(&request.email).await
                .map_err(|e| {
                    error!("Login lookup failed: {}", e);
                    ApiError::AuthenticationError("ユーザー名またはパスワードが無効です".into())
                })?
        };

        // Check if account is locked
        if login.is_account_locked() {
            warn!("Account locked for user: {}", request.email);
            return Err(ApiError::AuthenticationError(
                "アカウントがロックされています。しばらく経ってからもう一度試してください".into()
            ));
        }

        // Verify password
        let password_valid = verify(&request.password, &login.pass_word).map_err(|e| {
            error!("Password verification error: {}", e);
            ApiError::InternalServerError
        })?;
        
        if !password_valid {
            // Record failed login attempt
            if let Err(e) = self.repo.record_failed_login_attempt(&login.login_id, "Invalid password").await {
                error!("Failed to record login attempt: {}", e);
                // Continue with error response even if recording failed
            }
                
            return Err(ApiError::AuthenticationError("ユーザー名またはパスワードが無効です".into()));
        }
        
        // If there were previous failed attempts, reset them
        if login.login_failed_count > 0 {
            if let Err(e) = self.repo.reset_failed_login_attempts(&login.login_id).await {
                error!("Failed to reset login attempts: {}", e);
                // Continue even if reset failed
            }
        }

        // Generate JWT tokens
        let user_type = if login.is_owner() { "owner" } else { "user" };
        let token = generate_jwt(&login.login_id.to_string(), user_type)?;
        let refresh_token = generate_refresh_token(&login.login_id.to_string())?;

        // Record successful login
        if let Err(e) = self.repo.record_successful_login(&login.login_id, &token).await {
            error!("Failed to record successful login: {}", e);
            // Continue even if recording failed
        }

        // Get user info based on type
        let is_owner = login.is_owner();
        let response = if is_owner {
            let owner = self.repo.get_owner_by_login_id(&login.login_id).await
                .map_err(|e| {
                    error!("Failed to get owner information: {}", e);
                    ApiError::InternalServerError
                })?;
                
            SignInResponse {
                id: login.login_id,
                email: login.email,
                phone_number: login.phone_number,
                is_owner: true,
                full_name: owner.unwrap().full_name,
                token,
                refresh_token,
            }
        } else {
            let user = self.repo.get_user_by_login_id(&login.login_id).await
                .map_err(|e| {
                    error!("Failed to get user information: {}", e);
                    ApiError::InternalServerError
                })?;
                
            SignInResponse {
                id: login.login_id,
                email: login.email,
                phone_number: login.phone_number,
                is_owner: false,
                full_name: user.unwrap().full_name,
                token,
                refresh_token,
            }
        };

        info!("User authenticated successfully: {}", request.email);
        Ok(response)
    }

    /// Sign out a user
    /// 
    /// # Arguments
    /// * `login_id` - The ID of the user to sign out
    /// 
    /// # Returns
    /// Result indicating success or failure
    pub async fn signout(&self, login_id: &str) -> Result<(), ApiError> {
        debug!("Signing out user: {}", login_id);
        
        let login_id = Uuid::parse_str(login_id).map_err(|_| {
            ApiError::ValidationError("無効なユーザーIDです".into())
        })?;
        
        self.repo.record_logout(&login_id).await
            .map_err(|e| {
                error!("Failed to record logout: {}", e);
                ApiError::InternalServerError
            })?;
            
        info!("User signed out successfully: {}", login_id);
        Ok(())
    }

    /// Refresh the JWT token using a refresh token
    /// 
    /// # Arguments
    /// * `request` - RefreshTokenRequest containing the refresh token
    /// 
    /// # Returns
    /// SignInResponse containing new authentication tokens
    pub async fn refresh_token(&self, request: &RefreshTokenRequest) -> Result<SignInResponse, ApiError> {
        debug!("Refreshing token");
        
        // Verify refresh token
        let claims = verify_refresh_token(&request.refresh_token)?;
        let login_id = Uuid::parse_str(&claims.sub).map_err(|_| {
            ApiError::ValidationError("無効なユーザーIDです".into())
        })?;
        
        // Get user login data
        let login = self.repo.get_login_by_id(&login_id).await
            .map_err(|e| {
                error!("Failed to get login information: {}", e);
                ApiError::InternalServerError
            })?;

        // Generate new tokens
        let user_type = if login.is_owner() { "owner" } else { "user" };
        let token = generate_jwt(&login.login_id.to_string(), user_type)?;
        let new_refresh_token = generate_refresh_token(&login.login_id.to_string())?;

        // Return user information based on type
        let is_owner = login.is_owner();
        let response = if is_owner {
            let owner = self.repo.get_owner_by_login_id(&login.login_id).await
                .map_err(|e| {
                    error!("Failed to get owner information: {}", e);
                    ApiError::InternalServerError
                })?;
                
            SignInResponse {
                id: login.login_id,
                email: login.email,
                phone_number: login.phone_number,
                is_owner: true,
                full_name: owner.unwrap().full_name,
                token,
                refresh_token: new_refresh_token,
            }
        } else {
            let user = self.repo.get_user_by_login_id(&login.login_id).await
                .map_err(|e| {
                    error!("Failed to get user information: {}", e);
                    ApiError::InternalServerError
                })?;
                
            SignInResponse {
                id: login.login_id,
                email: login.email,
                phone_number: login.phone_number,
                is_owner: false,
                full_name: user.unwrap().full_name,
                token,
                refresh_token: new_refresh_token,
            }
        };

        info!("Token refreshed successfully for user: {}", login_id);
        Ok(response)
    }

    /// Get user information
    /// 
    /// # Arguments
    /// * `login_id` - The ID of the user
    /// 
    /// # Returns
    /// JSON object containing user information
    pub async fn get_user_info(&self, login_id: &str) -> Result<serde_json::Value, ApiError> {
        debug!("Getting user info for: {}", login_id);
        
        let login_id = Uuid::parse_str(login_id).map_err(|_| {
            ApiError::ValidationError("無効なユーザーIDです".into())
        })?;
        
        let login = self.repo.get_login_by_id(&login_id).await
            .map_err(|e| {
                error!("Failed to get login information: {}", e);
                ApiError::InternalServerError
            })?;

        let is_owner = login.is_owner();
        let result = if is_owner {
            match self.repo.get_owner_by_login_id(&login.login_id).await {
                Ok(Some(owner)) => {
                    serde_json::json!({
                        "id": login.login_id,
                        "email": login.email,
                        "phone_number": login.phone_number,
                        "is_owner": true,
                        "full_name": owner.full_name,
                        "full_name_kana": owner.full_name_kana,
                        "postal_code": owner.postal_code,
                        "address": owner.address,
                        "registrant_type": owner.registrant_type,
                        "remarks": owner.remarks
                    })
                },
                Ok(None) => {
                    return Err(ApiError::NotFoundError("オーナー情報が見つかりません".into()));
                },
                Err(e) => {
                    error!("Failed to get owner information: {}", e);
                    return Err(ApiError::InternalServerError);
                }
            }
        } else {
            match self.repo.get_user_by_login_id(&login.login_id).await {
                Ok(Some(user)) => {
                    serde_json::json!({
                        "id": login.login_id,
                        "email": login.email,
                        "phone_number": login.phone_number,
                        "is_owner": false,
                        "full_name": user.full_name,
                        "address": user.address,
                        "promotional_email_opt": user.promotional_email_opt,
                        "service_email_opt": user.service_email_opt
                    })
                },
                Ok(None) => {
                    return Err(ApiError::NotFoundError("ユーザー情報が見つかりません".into()));
                },
                Err(e) => {
                    error!("Failed to get user information: {}", e);
                    return Err(ApiError::InternalServerError);
                }
            }
        };

        Ok(result)
    }

    /// Update user profile
    /// 
    /// # Arguments
    /// * `login_id` - The ID of the user to update
    /// * `req` - Update request containing new user data
    /// 
    /// # Returns
    /// JSON object containing updated user information
    pub async fn update_user(&self, login_id: &str, req: &UpdateUserRequest) -> Result<serde_json::Value, ApiError> {
        debug!("Updating user profile for: {}", login_id);
        
        let login_id = Uuid::parse_str(login_id).map_err(|_| {
            ApiError::ValidationError("無効なユーザーIDです".into())
        })?;
        
        let login = self.repo.get_login_by_id(&login_id).await
            .map_err(|e| {
                error!("Failed to get login information: {}", e);
                ApiError::InternalServerError
            })?;

        // Validate phone number if provided
        if let Some(phone) = &req.phone_number {
            if !phone.is_empty() {
                Validator::validate_phone(phone)?;
            }
        }

        if login.is_owner() {
            match self.repo.get_owner_by_login_id(&login.login_id).await {
                Ok(Some(mut owner)) => {
                    // Update owner fields
                    if let Some(full_name) = &req.full_name {
                        owner.full_name = full_name.clone();
                    }
                    if let Some(phone_number) = &req.phone_number {
                        owner.phone_number = phone_number.clone();
                    }
                    if let Some(address) = &req.address {
                        owner.address = address.clone();
                    }
                    
                    // Update owner record
                    // TODO: Implement owner update in repository
                    
                    Ok(serde_json::json!({
                        "id": login.login_id,
                        "email": login.email,
                        "phone_number": login.phone_number,
                        "is_owner": true,
                        "full_name": owner.full_name,
                        "address": owner.address
                    }))
                },
                Ok(None) => {
                    Err(ApiError::NotFoundError("オーナー情報が見つかりません".into()))
                },
                Err(e) => {
                    error!("Failed to get owner information: {}", e);
                    Err(ApiError::InternalServerError)
                }
            }
        } else {
            match self.repo.get_user_by_login_id(&login.login_id).await {
                Ok(Some(mut user)) => {
                    // Update user fields
                    if let Some(full_name) = &req.full_name {
                        user.full_name = full_name.clone();
                    }
                    if let Some(phone_number) = &req.phone_number {
                        user.phone_number = Some(phone_number.clone());
                    }
                    if let Some(address) = &req.address {
                        user.address = address.clone();
                    }
                    
                    // Promotional and service email options - use existing values if not provided
                    if let Some(promotional_opt) = &req.promotional_email_opt {
                        user.promotional_email_opt = Some(promotional_opt.clone());
                    }
                    if let Some(service_opt) = &req.service_email_opt {
                        user.service_email_opt = Some(service_opt.clone());
                    }
                    
                    // Update user record
                    // TODO: Implement user update in repository
                    
                    Ok(serde_json::json!({
                        "id": login.login_id,
                        "email": login.email,
                        "phone_number": login.phone_number,
                        "is_owner": false,
                        "full_name": user.full_name,
                        "address": user.address
                    }))
                },
                Ok(None) => {
                    Err(ApiError::NotFoundError("ユーザー情報が見つかりません".into()))
                },
                Err(e) => {
                    error!("Failed to get user information: {}", e);
                    Err(ApiError::InternalServerError)
                }
            }
        }
    }

    /// Change user password
    /// 
    /// # Arguments
    /// * `login_id` - The ID of the user
    /// * `old_password` - Current password
    /// * `new_password` - New password
    /// 
    /// # Returns
    /// Result indicating success or failure
    pub async fn change_password(
        &self, 
        login_id: &str, 
        old_password: &str, 
        new_password: &str
    ) -> Result<(), ApiError> {
        debug!("Changing password for user: {}", login_id);
        
        // Validate new password
        Validator::validate_password(new_password)?;
        
        let login_id = Uuid::parse_str(login_id).map_err(|_| {
            ApiError::ValidationError("無効なユーザーIDです".into())
        })?;
        
        let login = self.repo.get_login_by_id(&login_id).await
            .map_err(|e| {
                error!("Failed to get login information: {}", e);
                ApiError::InternalServerError
            })?;

        // Verify current password
        let password_valid = verify(old_password, &login.pass_word).map_err(|e| {
            error!("Password verification error: {}", e);
            ApiError::InternalServerError
        })?;
        
        if !password_valid {
            return Err(ApiError::ValidationError("現在のパスワードが正しくありません".into()));
        }

        // Hash new password
        let new_hashed_password = hash(new_password, DEFAULT_COST).map_err(|e| {
            error!("Password hashing error: {}", e);
            ApiError::InternalServerError
        })?;
        
        // Update password
        self.repo.update_password(&login.login_id, &new_hashed_password).await
            .map_err(|e| {
                error!("Failed to update password: {}", e);
                ApiError::InternalServerError
            })?;
            
        info!("Password changed successfully for user: {}", login_id);
        Ok(())
    }

    /// Register a new user
    /// 
    /// # Arguments
    /// * `request` - Registration request
    /// 
    /// # Returns
    /// Result containing the login ID of the new user
    pub async fn register(&self, request: &RegisterRequest) -> Result<Uuid, ApiError> {
        debug!("Registering new {}: {}", 
            if request.is_owner { "owner" } else { "user" }, 
            request.email
        );
        
        // Validate input
        Validator::validate_register_request(
            &request.email,
            &request.phone_number,
            &request.password,
            &request.full_name,
            &request.address
        )?;
        
        // Check if email already exists
        let email_exists = self.repo.check_email_exists(&request.email).await
            .map_err(|e| {
                error!("Failed to check email existence: {}", e);
                ApiError::InternalServerError
            })?;
            
        if email_exists {
            return Err(ApiError::DuplicateError("このメールアドレスは既に使用されています".into()));
        }
        
        // Check if phone already exists
        let phone_exists = self.repo.check_phone_exists(&request.phone_number).await
            .map_err(|e| {
                error!("Failed to check phone existence: {}", e);
                ApiError::InternalServerError
            })?;
            
        if phone_exists {
            return Err(ApiError::DuplicateError("この電話番号は既に使用されています".into()));
        }
        
        // Hash password
        let hashed_password = hash(&request.password, DEFAULT_COST).map_err(|e| {
            error!("Password hashing error: {}", e);
            ApiError::InternalServerError
        })?;
        
        // Create login model
        use crate::models::auth_login_model::NewLogin;
        let new_login = NewLogin {
            email: request.email.clone(),
            phone_number: request.phone_number.clone(),
            pass_word: hashed_password,
            is_user_owner: if request.is_owner { "1".to_string() } else { "0".to_string() },
        };
        
        // Create login entry
        let login_id = self.repo.create_login(&new_login).await
            .map_err(|e| {
                error!("Failed to create login entry: {}", e);
                ApiError::InternalServerError
            })?;
        
        // Create user or owner based on type
        if !request.is_owner {
            // Create regular user
            use crate::models::auth_user_model::NewUser;
            let new_user = NewUser {
                login_id,
                full_name: request.full_name.clone(),
                phone_number: Some(request.phone_number.clone()),
                address: request.address.clone(),
                promotional_email_opt: Some("0".to_string()), // Default values
                service_email_opt: Some("1".to_string()),     // Default values
            };
            
            let user_id = self.repo.create_user(&new_user).await
                .map_err(|e| {
                    error!("Failed to create user: {}", e);
                    ApiError::InternalServerError
                })?;
                
            info!("Successfully registered new user with ID: {} (login_id: {})", user_id, login_id);
        } else {
            // Create owner with required fields
            use crate::models::auth_owner_model::NewOwner;
            
            if request.postal_code.is_none() {
                return Err(ApiError::ValidationError("郵便番号は必須です".into()));
            }
            
            let postal_code = request.postal_code.as_ref().unwrap();
            Validator::validate_postal_code(postal_code)?;
            
            let new_owner = NewOwner {
                login_id,
                registrant_type: request.registrant_type.clone().unwrap_or_else(|| "個人".to_string()),
                full_name: request.full_name.clone(),
                full_name_kana: request.full_name_kana.clone(),
                postal_code: postal_code.clone(),
                address: request.address.clone(),
                phone_number: request.phone_number.clone(),
                remarks: request.remarks.clone(),
            };
            
            let owner_id = self.repo.create_owner(&new_owner).await
                .map_err(|e| {
                    error!("Failed to create owner: {}", e);
                    ApiError::InternalServerError
                })?;
                
            info!("Successfully registered new owner with ID: {} (login_id: {})", owner_id, login_id);
        }
        
        Ok(login_id)
    }

    /// Generate and store verification code
    /// 
    /// # Arguments
    /// * `email` - The email to send verification code to
    /// * `verification_type` - Type of verification (email or SMS)
    /// 
    /// # Returns
    /// The generated verification code
    pub async fn generate_verification_code(
        &self,
        email: &str,
        verification_type: VerificationType
    ) -> Result<String, ApiError> {
        let _ = verification_type;
        debug!("Generating verification code for: {}", email);
        
        // Validate email
        Validator::validate_email(email)?;
        
        // Generate random 6-digit code
        let mut rng = rand::rng();
        let code = format!("{:06}", rng.random_range(0..1000000));
        
        // Store code with expiration (10 minutes)
        let _expires_at = Utc::now() + Duration::minutes(10);
        // TODO: Implement store_verification_code in repository
        
        // Note: In a real implementation, you would send the code via email or SMS here
        
        info!("Verification code generated for: {}", email);
        Ok(code)
    }

    /// Verify a verification code
    /// 
    /// # Arguments
    /// * `request` - Verification request
    /// 
    /// # Returns
    /// Result indicating success or failure
    pub async fn verify_code(&self, request: &VerifyCodeRequest) -> Result<bool, ApiError> {
        debug!("Verifying code for: {}", request.email);
        
        // Validate input
        Validator::validate_email(&request.email)?;
        Validator::validate_verification_code(&request.code)?;
        
        // TODO: Implement verify_code in repository
        // Mock successful verification for now
        let is_valid = true;
        
        if is_valid {
            info!("Verification code successfully verified for: {}", request.email);
        } else {
            warn!("Invalid verification code for: {}", request.email);
        }
        
        Ok(is_valid)
    }

    /// Resend verification code
    /// 
    /// # Arguments
    /// * `request` - Resend request
    /// 
    /// # Returns
    /// Result indicating success or failure
    pub async fn resend_verification_code(&self, request: &ResendCodeRequest) -> Result<(), ApiError> {
        debug!("Resending verification code for: {}", request.email);
        
        // Generate new code
        let _code = self.generate_verification_code(&request.email, request.verification_type.clone()).await?;
        
        // In a real implementation, you would send the code via email or SMS here
        
        info!("Verification code resent for: {}", request.email);
        Ok(())
    }

    /// Mark a user's email as verified
    /// 
    /// # Arguments
    /// * `email` - The email to mark as verified
    /// 
    /// # Returns
    /// Result indicating success or failure
    pub async fn mark_email_verified(&self, email: &str) -> Result<(), ApiError> {
        debug!("Marking email as verified: {}", email);
        
        // Get login by email
        let _login = self.repo.get_login_by_email(email).await
            .map_err(|e| {
                error!("Failed to get login information: {}", e);
                ApiError::InternalServerError
            })?;
            
        // Mark email as verified
        // TODO: Implement mark_email_verified in repository
        
        info!("Email marked as verified: {}", email);
        Ok(())
    }
}