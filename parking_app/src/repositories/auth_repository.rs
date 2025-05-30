use crate::controllers::api_error::ApiError;
use crate::models::{
    auth_login_model::{Login, NewLogin, VerificationType},
    auth_owner_model::{NewOwner, Owner},
    auth_user_model::{NewUser, User},
};
use chrono::Utc;
use sqlx::{postgres::PgPool, Postgres, Transaction};
use tracing::{debug, error};
use uuid::Uuid;

/// Authentication and user management related database operations
pub struct AuthRepository {
    pool: PgPool,
}

impl AuthRepository {
    /// Create a new AuthRepository with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Get login information by ID
    pub async fn get_login_by_id(&self, login_id: &Uuid) -> Result<Login, ApiError> {
        debug!("Fetching login by ID: {}", login_id);

        let sql = "
            SELECT 
                login_id, email, phone_number, pass_word, is_user_owner,
                login_token, login_token_expiration, login_token_issued_datetime, 
                login_token_issued_count, login_token_issued_flag, is_login,
                login_datetime, logout_datetime, login_failed_count,
                login_failed_datetime, login_failed_flag, login_failed_reason,
                login_failed_reason_detail, login_failed_reset_datetime,
                created_datetime, updated_datetime
            FROM m_login 
            WHERE login_id = $1
        ";

        let login = sqlx::query_as::<_, Login>(sql)
            .bind(login_id)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("ユーザーが見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("ログイン情報の取得に失敗しました: {}", e))
                }
            })?;

        Ok(login)
    }

    /// Get login information by email
    pub async fn get_login_by_email(&self, email: &str) -> Result<Login, ApiError> {
        debug!("Fetching login by email: {}", email);

        let sql = "
            SELECT 
                login_id, email, phone_number, pass_word, is_user_owner,
                login_token, login_token_expiration, login_token_issued_datetime, 
                login_token_issued_count, login_token_issued_flag, is_login,
                login_datetime, logout_datetime, login_failed_count,
                login_failed_datetime, login_failed_flag, login_failed_reason,
                login_failed_reason_detail, login_failed_reset_datetime,
                created_datetime, updated_datetime
            FROM m_login 
            WHERE email = $1
        ";

        let login = sqlx::query_as::<_, Login>(sql)
            .bind(email)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("ユーザーが見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("ログイン情報の取得に失敗しました: {}", e))
                }
            })?;

        Ok(login)
    }

    /// Get login information by phone number
    pub async fn get_login_by_phone(&self, phone: &str) -> Result<Login, ApiError> {
        debug!("Fetching login by phone: {}", phone);

        let sql = "
            SELECT 
                login_id, email, phone_number, pass_word, is_user_owner,
                login_token, login_token_expiration, login_token_issued_datetime, 
                login_token_issued_count, login_token_issued_flag, is_login,
                login_datetime, logout_datetime, login_failed_count,
                login_failed_datetime, login_failed_flag, login_failed_reason,
                login_failed_reason_detail, login_failed_reset_datetime,
                created_datetime, updated_datetime
            FROM m_login 
            WHERE phone_number = $1
        ";

        let login = sqlx::query_as::<_, Login>(sql)
            .bind(phone)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("ユーザーが見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("ログイン情報の取得に失敗しました: {}", e))
                }
            })?;

        Ok(login)
    }

    /// Get user information by login ID
    pub async fn get_user_by_login_id(&self, login_id: &Uuid) -> Result<Option<User>, ApiError> {
        debug!("Fetching user by login ID: {}", login_id);

        let sql = "
            SELECT 
                user_id, login_id, full_name, phone_number, address, 
                promotional_email_opt, service_email_opt,
                created_datetime, updated_datetime
            FROM m_users 
            WHERE login_id = $1
        ";

        let user = sqlx::query_as::<_, User>(sql)
            .bind(login_id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ユーザー情報の取得に失敗しました: {}", e))
            })?;

        Ok(user)
    }

    /// Get owner information by login ID
    pub async fn get_owner_by_login_id(&self, login_id: &Uuid) -> Result<Option<Owner>, ApiError> {
        debug!("Fetching owner by login ID: {}", login_id);

        let sql = "
            SELECT 
                owner_id, login_id, registrant_type, full_name, full_name_kana, 
                postal_code, address, phone_number, remarks, 
                created_datetime, updated_datetime
            FROM m_owners 
            WHERE login_id = $1
        ";

        let owner = sqlx::query_as::<_, Owner>(sql)
            .bind(login_id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("オーナー情報の取得に失敗しました: {}", e))
            })?;

        Ok(owner)
    }

    /// Check if email exists
    pub async fn check_email_exists(&self, email: &str) -> Result<bool, ApiError> {
        debug!("Checking if email exists: {}", email);

        let sql = "SELECT EXISTS(SELECT 1 FROM m_login WHERE email = $1) as exists";

        let result = sqlx::query_scalar::<_, bool>(sql)
            .bind(email)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("メールの存在確認に失敗しました: {}", e))
            })?;

        Ok(result)
    }

    /// Check if phone number exists
    pub async fn check_phone_exists(&self, phone_number: &str) -> Result<bool, ApiError> {
        debug!("Checking if phone exists: {}", phone_number);

        let sql = "SELECT EXISTS(SELECT 1 FROM m_login WHERE phone_number = $1) as exists";

        let result = sqlx::query_scalar::<_, bool>(sql)
            .bind(phone_number)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("電話番号の存在確認に失敗しました: {}", e))
            })?;

        Ok(result)
    }

    /// Create new login entry
    pub async fn create_login(&self, new_login: &NewLogin) -> Result<Uuid, ApiError> {
        debug!("Creating new login for email: {}", new_login.email);

        // トランザクション開始
        let mut tx = self.begin_transaction().await?;

        let sql = "
            INSERT INTO m_login
            (email, phone_number, pass_word, is_user_owner,
             login_token_issued_count, login_token_issued_flag, is_login,
             login_failed_count, login_failed_flag, created_datetime, updated_datetime)
            VALUES ($1, $2, $3, $4, 0, '0', '0', 0, '0', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING login_id
        ";

        let login_id: Uuid = sqlx::query_scalar(sql)
            .bind(&new_login.email)
            .bind(&new_login.phone_number)
            .bind(&new_login.pass_word)
            .bind(&new_login.is_user_owner)
            .fetch_one(&mut *tx)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ログイン情報の作成に失敗しました: {}", e))
            })?;

        tx.commit().await.map_err(|e| {
            error!("Transaction commit error: {:?}", e);
            ApiError::DatabaseError(format!("トランザクションのコミットに失敗しました: {}", e))
        })?;

        Ok(login_id)
    }

    /// Create new user
    pub async fn create_user(&self, new_user: &NewUser) -> Result<String, ApiError> {
        debug!("Creating new user for login_id: {}", new_user.login_id);

        // トランザクション開始
        let mut tx = self.begin_transaction().await?;

        let sql = "
            INSERT INTO m_users
            (login_id, full_name, phone_number, address, 
             promotional_email_opt, service_email_opt,
             created_datetime, updated_datetime)
            VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING user_id
        ";

        let user_id: String = sqlx::query_scalar(sql)
            .bind(new_user.login_id)
            .bind(&new_user.full_name)
            .bind(&new_user.phone_number)
            .bind(&new_user.address)
            .bind(&new_user.promotional_email_opt)
            .bind(&new_user.service_email_opt)
            .fetch_one(&mut *tx)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ユーザー情報の作成に失敗しました: {}", e))
            })?;

        tx.commit().await.map_err(|e| {
            error!("Transaction commit error: {:?}", e);
            ApiError::DatabaseError(format!("トランザクションのコミットに失敗しました: {}", e))
        })?;

        Ok(user_id)
    }

    /// Create new owner
    pub async fn create_owner(&self, new_owner: &NewOwner) -> Result<String, ApiError> {
        debug!("Creating new owner for login_id: {}", new_owner.login_id);

        // トランザクション開始
        let mut tx = self.begin_transaction().await?;

        let sql = "
            INSERT INTO m_owners
            (login_id, registrant_type, full_name, full_name_kana, 
             postal_code, address, phone_number, remarks,
             created_datetime, updated_datetime)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING owner_id
        ";

        let owner_id: String = sqlx::query_scalar(sql)
            .bind(new_owner.login_id)
            .bind(&new_owner.registrant_type)
            .bind(&new_owner.full_name)
            .bind(&new_owner.full_name_kana)
            .bind(&new_owner.postal_code)
            .bind(&new_owner.address)
            .bind(&new_owner.phone_number)
            .bind(&new_owner.remarks)
            .fetch_one(&mut *tx)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("オーナー情報の作成に失敗しました: {}", e))
            })?;

        tx.commit().await.map_err(|e| {
            error!("Transaction commit error: {:?}", e);
            ApiError::DatabaseError(format!("トランザクションのコミットに失敗しました: {}", e))
        })?;

        Ok(owner_id)
    }

    /// Record a successful login
    pub async fn record_successful_login(
        &self,
        login_id: &Uuid,
        token: &str,
    ) -> Result<(), ApiError> {
        debug!("Recording successful login for user: {}", login_id);

        let now = Utc::now();
        let token_expiration = now + chrono::Duration::hours(24);

        let sql = "
            UPDATE m_login 
            SET is_login = '1',
                login_datetime = $2,
                login_token = $3,
                login_token_expiration = $4,
                login_token_issued_datetime = $2,
                login_token_issued_count = login_token_issued_count + 1,
                login_token_issued_flag = '1',
                login_failed_flag = '0',
                updated_datetime = $2
            WHERE login_id = $1
        ";

        sqlx::query(sql)
            .bind(login_id)
            .bind(now)
            .bind(token)
            .bind(token_expiration)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ログイン状態の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Record a failed login attempt
    pub async fn record_failed_login_attempt(
        &self,
        login_id: &Uuid,
        reason: &str,
    ) -> Result<(), ApiError> {
        debug!("Recording failed login attempt for user: {}", login_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_login 
            SET login_failed_count = login_failed_count + 1,
                login_failed_datetime = $2,
                login_failed_flag = '1',
                login_failed_reason = $3,
                updated_datetime = $2
            WHERE login_id = $1
        ";

        sqlx::query(sql)
            .bind(login_id)
            .bind(now)
            .bind(reason)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ログイン失敗情報の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Reset failed login attempts
    pub async fn reset_failed_login_attempts(&self, login_id: &Uuid) -> Result<(), ApiError> {
        debug!("Resetting failed login attempts for user: {}", login_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_login 
            SET login_failed_count = 0,
                login_failed_flag = '0',
                login_failed_reset_datetime = $2,
                updated_datetime = $2
            WHERE login_id = $1
        ";

        sqlx::query(sql)
            .bind(login_id)
            .bind(now)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ログイン失敗情報のリセットに失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Record a logout
    pub async fn record_logout(&self, login_id: &Uuid) -> Result<(), ApiError> {
        debug!("Recording logout for user: {}", login_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_login 
            SET is_login = '0',
                logout_datetime = $2,
                login_token = NULL,
                updated_datetime = $2
            WHERE login_id = $1
        ";

        sqlx::query(sql)
            .bind(login_id)
            .bind(now)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ログアウト情報の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Update user information
    pub async fn update_user(&self, user: &User) -> Result<(), ApiError> {
        debug!("Updating user profile for user_id: {}", user.user_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_users 
            SET full_name = $1,
                phone_number = $2,
                address = $3,
                promotional_email_opt = $4,
                service_email_opt = $5,
                updated_datetime = $6
            WHERE user_id = $7
        ";

        sqlx::query(sql)
            .bind(&user.full_name)
            .bind(&user.phone_number)
            .bind(&user.address)
            .bind(&user.promotional_email_opt)
            .bind(&user.service_email_opt)
            .bind(now)
            .bind(&user.user_id)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("ユーザー情報の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Update owner information
    pub async fn update_owner(&self, owner: &Owner) -> Result<(), ApiError> {
        debug!("Updating owner profile for owner_id: {}", owner.owner_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_owners 
            SET full_name = $1,
                full_name_kana = $2,
                postal_code = $3,
                address = $4,
                phone_number = $5,
                remarks = $6,
                updated_datetime = $7
            WHERE owner_id = $8
        ";

        sqlx::query(sql)
            .bind(&owner.full_name)
            .bind(&owner.full_name_kana)
            .bind(&owner.postal_code)
            .bind(&owner.address)
            .bind(&owner.phone_number)
            .bind(&owner.remarks)
            .bind(now)
            .bind(&owner.owner_id)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("オーナー情報の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Update password
    pub async fn update_password(
        &self,
        login_id: &Uuid,
        hashed_password: &str,
    ) -> Result<(), ApiError> {
        debug!("Updating password for login_id: {}", login_id);

        let now = Utc::now();

        let sql = "
            UPDATE m_login 
            SET pass_word = $2,
                updated_datetime = $3
            WHERE login_id = $1
        ";

        sqlx::query(sql)
            .bind(login_id)
            .bind(hashed_password)
            .bind(now)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("パスワードの更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Store verification code
    pub async fn store_verification_code(
        &self,
        email: &str,
        code: &str,
        verification_type: VerificationType,
        expires_at: chrono::DateTime<chrono::Utc>,
    ) -> Result<(), ApiError> {
        debug!("Storing verification code for email: {}", email);

        let verification_type_str = match verification_type {
            VerificationType::Email => "email",
            VerificationType::SMS => "sms",
        };

        // First check if the table exists
        let table_exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS (
                SELECT 1 
                FROM information_schema.tables 
                WHERE table_name = 'verification_codes'
            )",
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("テーブル存在確認に失敗しました: {}", e))
        })?;

        if !table_exists {
            debug!("Creating verification_codes table");
            sqlx::query(
                "CREATE TABLE verification_codes (
                    id SERIAL PRIMARY KEY,
                    email VARCHAR(255) NOT NULL,
                    code VARCHAR(10) NOT NULL,
                    verification_type VARCHAR(20) NOT NULL,
                    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE (email, verification_type)
                )",
            )
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("検証コードテーブルの作成に失敗しました: {}", e))
            })?;
        }

        // Now insert or update the verification code
        let sql = "
            INSERT INTO verification_codes (
                email, code, verification_type, expires_at
            )
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (email, verification_type) 
            DO UPDATE SET 
                code = EXCLUDED.code, 
                expires_at = EXCLUDED.expires_at, 
                created_at = CURRENT_TIMESTAMP
        ";

        sqlx::query(sql)
            .bind(email)
            .bind(code)
            .bind(verification_type_str)
            .bind(expires_at)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("検証コードの保存に失敗しました: {}", e))
            })?;

        Ok(())
    }

    /// Verify verification code
    pub async fn verify_code(
        &self,
        email: &str,
        code: &str,
        verification_type: VerificationType,
    ) -> Result<bool, ApiError> {
        debug!("Verifying code for email: {}", email);

        let verification_type_str = match verification_type {
            VerificationType::Email => "email",
            VerificationType::SMS => "sms",
        };

        // First check if the table exists
        let table_exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS (
                SELECT 1 
                FROM information_schema.tables 
                WHERE table_name = 'verification_codes'
            )",
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("テーブル存在確認に失敗しました: {}", e))
        })?;

        if !table_exists {
            debug!("verification_codes table doesn't exist");
            return Ok(false);
        }

        let result = sqlx::query_as::<_, (String, chrono::DateTime<chrono::Utc>)>(
            "
            SELECT code, expires_at 
            FROM verification_codes 
            WHERE email = $1 AND verification_type = $2
            ",
        )
        .bind(email)
        .bind(verification_type_str)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("検証コードの取得に失敗しました: {}", e))
        })?;

        match result {
            Some((stored_code, expires_at)) => {
                let now = chrono::Utc::now();

                if stored_code == code && expires_at > now {
                    Ok(true)
                } else {
                    Ok(false)
                }
            }
            None => Ok(false),
        }
    }

    /// Mark email as verified
    pub async fn mark_email_verified(&self, login_id: &Uuid) -> Result<(), ApiError> {
        debug!("Marking email as verified for login_id: {}", login_id);

        // Check if email_verified column exists in m_login table
        let column_exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS (
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_name = 'm_login' AND column_name = 'email_verified'
            )",
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("カラム存在確認に失敗しました: {}", e))
        })?;

        if !column_exists {
            debug!("Adding email_verified column to m_login table");
            sqlx::query(
                "ALTER TABLE m_login 
                ADD COLUMN email_verified BOOLEAN DEFAULT FALSE",
            )
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("email_verified カラムの追加に失敗しました: {}", e))
            })?;
        }

        let now = Utc::now();

        sqlx::query(
            "UPDATE m_login 
            SET email_verified = true,
                updated_datetime = $2
            WHERE login_id = $1",
        )
        .bind(login_id)
        .bind(now)
        .execute(&self.pool)
        .await
        .map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("メール検証情報の更新に失敗しました: {}", e))
        })?;

        Ok(())
    }

    /// Begin a database transaction
    pub async fn begin_transaction(&self) -> Result<Transaction<'_, Postgres>, ApiError> {
        let tx = self.pool.begin().await.map_err(|e| {
            error!("Database error: {:?}", e);
            ApiError::DatabaseError(format!("トランザクションの開始に失敗しました: {}", e))
        })?;
        Ok(tx)
    }
}
