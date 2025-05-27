use bcrypt::{hash, DEFAULT_COST};
use tracing::{debug, error, instrument};

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

    // 入力値の検証を行う
    fn validate_user_input(&self, req: &UserSignupRequest) -> Result<(), ApiError> {
        // メールアドレスの長さチェック (通常は254文字まで)
        if req.email.len() > 254 {
            return Err(ApiError::ValidationError(
                "メールアドレスが長すぎます（254文字以内で入力してください）".to_string()
            ));
        }

        // 電話番号の長さチェック (通常は20文字まで)
        if req.phone_number.len() > 20 {
            return Err(ApiError::ValidationError(
                "電話番号が長すぎます（20文字以内で入力してください）".to_string()
            ));
        }

        // フルネームの長さチェック (通常は100文字まで)
        if req.full_name.len() > 100 {
            return Err(ApiError::ValidationError(
                "氏名が長すぎます（100文字以内で入力してください）".to_string()
            ));
        }

        // パスワードの長さチェック (最大255文字)
        if req.password.len() > 255 {
            return Err(ApiError::ValidationError(
                "パスワードが長すぎます（255文字以内で入力してください）".to_string()
            ));
        }

        Ok(())
    }

    // オーナー用入力値の検証を行う
    fn validate_owner_input(&self, req: &OwnerSignupRequest) -> Result<(), ApiError> {
        // メールアドレスの長さチェック
        if req.email.len() > 254 {
            return Err(ApiError::ValidationError(
                "メールアドレスが長すぎます（254文字以内で入力してください）".to_string()
            ));
        }

        // 電話番号の長さチェック
        if req.phone_number.len() > 20 {
            return Err(ApiError::ValidationError(
                "電話番号が長すぎます（20文字以内で入力してください）".to_string()
            ));
        }

        // フルネームの長さチェック
        if req.full_name.len() > 100 {
            return Err(ApiError::ValidationError(
                "氏名が長すぎます（100文字以内で入力してください）".to_string()
            ));
        }

        // パスワードの長さチェック
        if req.password.len() > 255 {
            return Err(ApiError::ValidationError(
                "パスワードが長すぎます（255文字以内で入力してください）".to_string()
            ));
        }

        // 登録者タイプの長さチェック
        if req.registrant_type.len() > 50 {
            return Err(ApiError::ValidationError(
                "登録者タイプが長すぎます（50文字以内で入力してください）".to_string()
            ));
        }

        Ok(())
    }

    #[instrument(skip(self, req), fields(email = %req.email, phone_number = %req.phone_number))]
    pub async fn register_user(&self, req: UserSignupRequest) -> Result<SignupResponse, ApiError> {
        debug!("ユーザー登録を開始します: {}", req.email);

        // 0. 入力値の検証
        self.validate_user_input(&req)?;

        // 1. メールアドレスの重複チェック
        if self.repository.email_exists(&req.email).await.map_err(|e| {
            error!("メールアドレス存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })? {
            return Err(ApiError::DuplicateError(
                "このメールアドレスは既に登録されています".to_string()
            ));
        }

        // 2. 電話番号の重複チェック
        if self.repository.phone_exists(&req.phone_number).await.map_err(|e| {
            error!("電話番号存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })? {
            return Err(ApiError::DuplicateError(
                "この電話番号は既に登録されています".to_string()
            ));
        }

        // 3. パスワードのハッシュ化
        let hashed_password = hash(&req.password, DEFAULT_COST).map_err(|e| {
            error!("パスワードのハッシュ化に失敗しました: {}", e);
            ApiError::InternalServerError
        })?;

        // 4. データベースへのユーザー作成
        let (_login_id, user_id) = self.repository.create_user(&req, &hashed_password).await
            .map_err(|db_err| {
                error!("ユーザー作成中にデータベースエラーが発生しました {}: {}", req.email, db_err);
                match db_err {
                    DatabaseError::QueryError(s) if s.contains("duplicate key") => {
                        ApiError::DuplicateError("このメールアドレスまたは電話番号は既に使用されています".into())
                    }
                    DatabaseError::QueryError(s) if s.contains("値太长了") || s.contains("too long") => {
                        ApiError::ValidationError("入力された値が長すぎます。各項目の文字数制限を確認してください".into())
                    }
                    _ => ApiError::InternalServerError,
                }
            })?;

        // 5. JWTトークンの生成
        let access_token = generate_jwt(&user_id, "user")?;
        let refresh_token = generate_refresh_token(&user_id)?;

        debug!("ユーザー登録が正常に完了しました: {}", req.email);
        
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
        debug!("オーナー登録を開始します: {} (タイプ: {})", req.email, req.registrant_type);

        // 0. 入力値の検証
        self.validate_owner_input(&req)?;

        // 1. メールアドレスの重複チェック
        if self.repository.email_exists(&req.email).await.map_err(|e| {
            error!("メールアドレス存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })? {
            return Err(ApiError::DuplicateError(
                "このメールアドレスは既に登録されています".to_string()
            ));
        }

        // 2. 電話番号の重複チェック
        if self.repository.phone_exists(&req.phone_number).await.map_err(|e| {
            error!("電話番号存在確認中にデータベースエラーが発生しました: {}", e);
            ApiError::InternalServerError
        })? {
            return Err(ApiError::DuplicateError(
                "この電話番号は既に登録されています".to_string()
            ));
        }

        // 3. パスワードのハッシュ化
        let hashed_password = hash(&req.password, DEFAULT_COST).map_err(|e| {
            error!("パスワードのハッシュ化に失敗しました: {}", e);
            ApiError::InternalServerError
        })?;

        // 4. データベースへのオーナー作成
        let (_login_id, owner_id) = self.repository.create_owner(&req, &hashed_password).await
            .map_err(|db_err| {
                error!("オーナー作成中にデータベースエラーが発生しました {}: {}", req.email, db_err);
                match db_err {
                    DatabaseError::QueryError(s) if s.contains("duplicate key") => {
                        ApiError::DuplicateError("このメールアドレスまたは電話番号は既に使用されています".into())
                    }
                    DatabaseError::QueryError(s) if s.contains("値太长了") || s.contains("too long") => {
                        ApiError::ValidationError("入力された値が長すぎます。各項目の文字数制限を確認してください".into())
                    }
                    _ => ApiError::InternalServerError,
                }
            })?;

        // 5. JWTトークンの生成
        let access_token = generate_jwt(&owner_id, "owner")?;
        let refresh_token = generate_refresh_token(&owner_id)?;

        debug!("オーナー登録が正常に完了しました: {}", req.email);
        
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
}
