use chrono::Utc;
use tracing::{error, info, instrument, warn};
use uuid::Uuid;

use crate::{
    config::logging::{log_sql_error, log_sql_query, SqlParam},
    config::postgresql_database::{DatabaseError, PostgresDatabase},
    models::auth_signup_model::{OwnerSignupRequest, UserSignupRequest},
    models::{LoginIdRow, OwnerIdRow, UserIdRow},
};

#[derive(Debug, Clone)]
pub struct AuthSignupRepository {
    db: PostgresDatabase,
}

impl AuthSignupRepository {
    pub fn new(db: PostgresDatabase) -> Self {
        Self { db }
    }

    #[instrument(skip(self, hashed_password))]
    pub async fn create_user(
        &self,
        req: &UserSignupRequest,
        hashed_password: &str,
    ) -> Result<(Uuid, String), DatabaseError> {
        info!("ユーザー作成を開始: {}", req.email);

        let mut tx = self.begin_transaction().await?;
        let now = Utc::now();

        // Insert into m_login
        let login_id = self
            .insert_login_record(
                &mut tx,
                &req.email,
                &req.phone_number,
                hashed_password,
                "0", // is_user_owner: 0 for users
                now,
            )
            .await?;

        // Parse birthday if provided
        let birthday_date = self.parse_birthday(req.birthday.as_deref());

        // Insert into m_users
        let user_id = self
            .insert_user_record(&mut tx, login_id, req, birthday_date, now)
            .await?;

        self.commit_transaction(tx).await?;

        info!("ユーザー作成が完了 - login_id: {}, user_id: {}", login_id, user_id);
        Ok((login_id, user_id))
    }

    #[instrument(skip(self, hashed_password))]
    pub async fn create_owner(
        &self,
        req: &OwnerSignupRequest,
        hashed_password: &str,
    ) -> Result<(Uuid, String), DatabaseError> {
        info!("オーナー作成を開始: {}", req.email);

        let mut tx = self.begin_transaction().await?;
        let now = Utc::now();

        // Insert into m_login
        let login_id = self
            .insert_login_record(
                &mut tx,
                &req.email,
                &req.phone_number,
                hashed_password,
                "1", // is_user_owner: 1 for owners
                now,
            )
            .await?;

        // Parse birthday if provided
        let birthday_date = self.parse_birthday(req.birthday.as_deref());

        // Insert into m_owners
        let owner_id = self
            .insert_owner_record(&mut tx, login_id, req, birthday_date, now)
            .await?;

        self.commit_transaction(tx).await?;

        info!("オーナー作成が完了 - login_id: {}, owner_id: {}", login_id, owner_id);
        Ok((login_id, owner_id))
    }

    /// メールアドレスの存在チェック
    #[instrument(skip(self))]
    pub async fn email_exists(&self, email: &str) -> Result<bool, DatabaseError> {
        let query = "SELECT EXISTS(SELECT 1 FROM m_login WHERE email = $1)";
        let params = vec![SqlParam::String(email.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_scalar::<_, bool>(query)
            .bind(email)
            .fetch_one(self.db.pool())
            .await
        {
            Ok(exists) => {
                info!("メールアドレス存在確認 {}: {}", email, exists);
                Ok(exists)
            }
            Err(e) => {
                error!("メールアドレス存在確認に失敗 {}: {}", email, e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "メールアドレス存在確認に失敗: {}",
                    e
                )))
            }
        }
    }

    /// 電話番号の存在チェック
    #[instrument(skip(self))]
    pub async fn phone_exists(&self, phone_number: &str) -> Result<bool, DatabaseError> {
        let query = "SELECT EXISTS(SELECT 1 FROM m_login WHERE phone_number = $1)";
        let params = vec![SqlParam::String(phone_number.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_scalar::<_, bool>(query)
            .bind(phone_number)
            .fetch_one(self.db.pool())
            .await
        {
            Ok(exists) => {
                info!("電話番号存在確認 {}: {}", phone_number, exists);
                Ok(exists)
            }
            Err(e) => {
                error!("電話番号存在確認に失敗 {}: {}", phone_number, e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "電話番号存在確認に失敗: {}",
                    e
                )))
            }
        }
    }

    // プライベートヘルパーメソッド

    /// トランザクションの開始
    async fn begin_transaction(&self) -> Result<sqlx::Transaction<'static, sqlx::Postgres>, DatabaseError> {
        self.db.pool().begin().await.map_err(|e| {
            error!("トランザクション開始に失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクション開始に失敗: {}", e))
        })
    }

    /// トランザクションのコミット
    async fn commit_transaction(&self, tx: sqlx::Transaction<'static, sqlx::Postgres>) -> Result<(), DatabaseError> {
        tx.commit().await.map_err(|e| {
            error!("トランザクションコミットに失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクションコミットに失敗: {}", e))
        })
    }

    /// 生年月日の解析
    fn parse_birthday(&self, birthday: Option<&str>) -> Option<chrono::NaiveDate> {
        birthday.and_then(|bday| {
            chrono::NaiveDate::parse_from_str(bday, "%Y-%m-%d")
                .map_err(|e| {
                    warn!("生年月日の解析に失敗: {} - {}", bday, e);
                    e
                })
                .ok()
        })
    }

    /// m_loginレコードの挿入
    async fn insert_login_record(
        &self,
        tx: &mut sqlx::Transaction<'static, sqlx::Postgres>,
        email: &str,
        phone_number: &str,
        hashed_password: &str,
        is_user_owner: &str,
        now: chrono::DateTime<Utc>,
    ) -> Result<Uuid, DatabaseError> {
        let login_sql = r#"
            INSERT INTO m_login 
            (email, phone_number, pass_word, is_user_owner, login_token_issued_flag, is_login, login_failed_flag, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
            RETURNING login_id
        "#;

        let login_params = vec![
            SqlParam::String(email.to_string()),
            SqlParam::String(phone_number.to_string()),
            SqlParam::String(hashed_password.to_string()),
            SqlParam::String(is_user_owner.to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(login_sql, &login_params, None);

        match sqlx::query_as::<_, LoginIdRow>(login_sql)
            .bind(email)
            .bind(phone_number)
            .bind(hashed_password)
            .bind(is_user_owner)
            .bind("0")
            .bind("0")
            .bind("0")
            .bind(now)
            .bind(now)
            .fetch_one(&mut **tx)
            .await
        {
            Ok(row) => {
                info!("m_loginレコード挿入成功");
                Ok(row.login_id)
            }
            Err(e) => {
                error!("m_loginレコード挿入に失敗: {}", e);
                log_sql_error(login_sql, &login_params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "m_loginレコード挿入に失敗: {}",
                    e
                )))
            }
        }
    }

    /// m_usersレコードの挿入
    async fn insert_user_record(
        &self,
        tx: &mut sqlx::Transaction<'static, sqlx::Postgres>,
        login_id: Uuid,
        req: &UserSignupRequest,
        birthday_date: Option<chrono::NaiveDate>,
        now: chrono::DateTime<Utc>,
    ) -> Result<String, DatabaseError> {
        let user_sql = r#"
            INSERT INTO m_users 
            (login_id, full_name, birthday, gender, phone_number, address, promotional_email_opt, service_email_opt, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
            RETURNING user_id
        "#;

        let promotional_opt = if req.promotional_email_opt_in.unwrap_or(false) { "1" } else { "0" };
        let service_opt = if req.service_email_opt_in.unwrap_or(false) { "1" } else { "0" };

        let user_params = vec![
            SqlParam::String(login_id.to_string()),
            SqlParam::String(req.full_name.clone()),
            if let Some(bd) = birthday_date {
                SqlParam::String(bd.to_string())
            } else {
                SqlParam::Null
            },
            if let Some(gender) = &req.gender {
                SqlParam::String(gender.clone())
            } else {
                SqlParam::Null
            },
            SqlParam::String(req.phone_number.clone()),
            SqlParam::String(req.address.clone()),
            SqlParam::String(promotional_opt.to_string()),
            SqlParam::String(service_opt.to_string()),
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(user_sql, &user_params, None);

        match sqlx::query_as::<_, UserIdRow>(user_sql)
            .bind(login_id)
            .bind(&req.full_name)
            .bind(birthday_date)
            .bind(req.gender.as_deref())
            .bind(&req.phone_number)
            .bind(&req.address)
            .bind(promotional_opt)
            .bind(service_opt)
            .bind(now)
            .bind(now)
            .fetch_one(&mut **tx)
            .await
        {
            Ok(row) => {
                info!("m_usersレコード挿入成功");
                Ok(row.user_id)
            }
            Err(e) => {
                error!("m_usersレコード挿入に失敗: {}", e);
                log_sql_error(user_sql, &user_params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "m_usersレコード挿入に失敗: {}",
                    e
                )))
            }
        }
    }

    /// m_ownersレコードの挿入
    async fn insert_owner_record(
        &self,
        tx: &mut sqlx::Transaction<'static, sqlx::Postgres>,
        login_id: Uuid,
        req: &OwnerSignupRequest,
        birthday_date: Option<chrono::NaiveDate>,
        now: chrono::DateTime<Utc>,
    ) -> Result<String, DatabaseError> {
        let owner_sql = r#"
            INSERT INTO m_owners 
            (login_id, registrant_type, full_name, full_name_kana, birthday, gender, postal_code, address, phone_number, remarks, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
            RETURNING owner_id
        "#;

        let owner_params = vec![
            SqlParam::String(login_id.to_string()),
            SqlParam::String(req.registrant_type.clone()),
            SqlParam::String(req.full_name.clone()),
            if let Some(kana) = &req.full_name_kana {
                SqlParam::String(kana.clone())
            } else {
                SqlParam::Null
            },
            if let Some(bd) = birthday_date {
                SqlParam::String(bd.to_string())
            } else {
                SqlParam::Null
            },
            if let Some(gender) = &req.gender {
                SqlParam::String(gender.clone())
            } else {
                SqlParam::Null
            },
            SqlParam::String(req.postal_code.clone()),
            SqlParam::String(req.address.clone()),
            SqlParam::String(req.phone_number.clone()),
            if let Some(remarks) = &req.remarks {
                SqlParam::String(remarks.clone())
            } else {
                SqlParam::Null
            },
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(owner_sql, &owner_params, None);

        match sqlx::query_as::<_, OwnerIdRow>(owner_sql)
            .bind(login_id)
            .bind(&req.registrant_type)
            .bind(&req.full_name)
            .bind(req.full_name_kana.as_deref())
            .bind(birthday_date)
            .bind(req.gender.as_deref())
            .bind(&req.postal_code)
            .bind(&req.address)
            .bind(&req.phone_number)
            .bind(req.remarks.as_deref())
            .bind(now)
            .bind(now)
            .fetch_one(&mut **tx)
            .await
        {
            Ok(row) => {
                info!("m_ownersレコード挿入成功");
                Ok(row.owner_id)
            }
            Err(e) => {
                error!("m_ownersレコード挿入に失敗: {}", e);
                log_sql_error(owner_sql, &owner_params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "m_ownersレコード挿入に失敗: {}",
                    e
                )))
            }
        }
    }
}
