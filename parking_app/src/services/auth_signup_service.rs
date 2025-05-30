use bcrypt::{hash, DEFAULT_COST};
use tracing::{error, instrument, info};

use crate::{
    config::postgresql_database::{DatabaseError, PostgresDatabase},
    controllers::api_error::ApiError,
    middlewares::jwt::{generate_jwt, generate_refresh_token},
    models::auth_signup_model::{
        OwnerSignupRequest, SignupResponse, UserSignupRequest,
    },
    repositories::auth_signup_repository::AuthSignupRepository,
};

#[derive(Debug, Clone)]
pub struct AuthSignupService {
    repository: AuthSignupRepository,
}

impl AuthSignupService {
    pub fn new(db: PostgresDatabase) -> Self {
        let repository = AuthSignupRepository::new(db);
        Self { repository }
    }

    #[instrument(skip(self, req), fields(email = %req.email, phone_number = %req.phone_number))]
    pub async fn register_user(&self, req: UserSignupRequest) -> Result<SignupResponse, ApiError> {
        info!("ユーザー登録を開始します: {}", req.email);

        // モデルの検証メソッドを使用
        req.validate().map_err(ApiError::ValidationError)?;

        // メールアドレスの重複チェック
        if self.check_email_duplicate(&req.email).await? {
            return Err(ApiError::DuplicateError(
                "このメールアドレスは既に登録されています".to_string()
            ));
        }

        // 電話番号の重複チェック
        if self.check_phone_duplicate(&req.phone_number).await? {
            return Err(ApiError::DuplicateError(
                "この電話番号は既に登録されています".to_string()
            ));
        }

        // パスワードのハッシュ化
        let hashed_password = self.hash_password(&req.password)?;

        // データベースへのユーザー作成
        let (_login_id, user_id) = self.repository
            .create_user(&req, &hashed_password)
            .await
            .map_err(|db_err| self.handle_database_error(db_err, &req.email))?;

        // JWTトークンの生成
        let (access_token, refresh_token) = self.generate_tokens(&user_id, "user")?;

        info!("ユーザー登録が正常に完了しました: {}", req.email);
        
        Ok(SignupResponse {
            id: user_id,
            email: req.email,
            phone_number: req.phone_number,
            full_name: req.full_name,
            user_type: "user".to_string(),
            is_verified: false,
            verification_code: None,
            access_token: Some(access_token),
            refresh_token: Some(refresh_token),
            created_at: chrono::Utc::now(),
        })
    }

    #[instrument(skip(self, req), fields(email = %req.email, phone_number = %req.phone_number, registrant_type = %req.registrant_type))]
    pub async fn register_owner(&self, req: OwnerSignupRequest) -> Result<SignupResponse, ApiError> {
        info!("オーナー登録を開始します: {} (タイプ: {})", req.email, req.registrant_type);

        // モデルの検証メソッドを使用
        req.validate().map_err(ApiError::ValidationError)?;

        // メールアドレスの重複チェック
        if self.check_email_duplicate(&req.email).await? {
            return Err(ApiError::DuplicateError(
                "このメールアドレスは既に登録されています".to_string()
            ));
        }

        // 電話番号の重複チェック
        if self.check_phone_duplicate(&req.phone_number).await? {
            return Err(ApiError::DuplicateError(
                "この電話番号は既に登録されています".to_string()
            ));
        }

        // パスワードのハッシュ化
        let hashed_password = self.hash_password(&req.password)?;

        // データベースへのオーナー作成
        let (_login_id, owner_id) = self.repository
            .create_owner(&req, &hashed_password)
            .await
            .map_err(|db_err| self.handle_database_error(db_err, &req.email))?;

        // JWTトークンの生成
        let (access_token, refresh_token) = self.generate_tokens(&owner_id, "owner")?;

        info!("オーナー登録が正常に完了しました: {}", req.email);
        
        Ok(SignupResponse {
            id: owner_id,
            email: req.email,
            phone_number: req.phone_number,
            full_name: req.full_name,
            user_type: "owner".to_string(),
            is_verified: false,
            verification_code: None,
            access_token: Some(access_token),
            refresh_token: Some(refresh_token),
            created_at: chrono::Utc::now(),
        })
    }

    // 共通ヘルパーメソッド

    /// メールアドレスの重複チェック
    async fn check_email_duplicate(&self, email: &str) -> Result<bool, ApiError> {
        self.repository.email_exists(email).await.map_err(|e| {
            error!("メールアドレス存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })
    }

    /// 電話番号の重複チェック
    async fn check_phone_duplicate(&self, phone_number: &str) -> Result<bool, ApiError> {
        self.repository.phone_exists(phone_number).await.map_err(|e| {
            error!("電話番号存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })
    }

    /// パスワードのハッシュ化
    fn hash_password(&self, password: &str) -> Result<String, ApiError> {
        hash(password, DEFAULT_COST).map_err(|e| {
            error!("パスワードのハッシュ化に失敗しました: {}", e);
            ApiError::InternalServerError
        })
    }

    /// JWTトークンの生成
    fn generate_tokens(&self, user_id: &str, user_type: &str) -> Result<(String, String), ApiError> {
        let access_token = generate_jwt(user_id, user_type)?;
        let refresh_token = generate_refresh_token(user_id)?;
        Ok((access_token, refresh_token))
    }

    /// データベースエラーの処理
    fn handle_database_error(&self, db_err: DatabaseError, email: &str) -> ApiError {
        error!("ユーザー作成中にデータベースエラーが発生しました {}: {}", email, db_err);
        
        match db_err {
            DatabaseError::QueryError(ref s) if s.contains("duplicate key") => {
                ApiError::DuplicateError(
                    "このメールアドレスまたは電話番号は既に使用されています".to_string()
                )
            }
            DatabaseError::QueryError(ref s) if s.contains("value too long") || s.contains("値太长了") => {
                ApiError::ValidationError(
                    "入力された値が長すぎます。各項目の文字数制限を確認してください".to_string()
                )
            }
            DatabaseError::TransactionError(_) => {
                error!("トランザクションエラーが発生しました");
                ApiError::InternalServerError
            }
            _ => ApiError::InternalServerError,
        }
    }
}
