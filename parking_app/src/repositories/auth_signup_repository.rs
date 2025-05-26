use chrono::Utc;
use tracing::{error, info, instrument};
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
        info!("Starting user creation for email: {}", req.email);

        let mut tx: sqlx::Transaction<'static, sqlx::Postgres> =
            self.db.pool().begin().await.map_err(|e| {
                error!("Failed to begin transaction for user creation: {}", e);
                DatabaseError::TransactionError(format!("Failed to begin transaction: {}", e))
            })?;

        // Insert into m_login
        let login_sql = r#"
            INSERT INTO m_login 
            (email, phone_number, pass_word, is_user_owner, login_token_issued_flag, is_login, login_failed_flag, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
            RETURNING login_id
        "#;
        let now = Utc::now();

        let login_params = vec![
            SqlParam::String(req.email.clone()),
            SqlParam::String(req.phone_number.clone()),
            SqlParam::String(hashed_password.to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(login_sql, &login_params, None);

        let login_id_row: LoginIdRow = match sqlx::query_as(login_sql)
            .bind(&req.email)
            .bind(&req.phone_number)
            .bind(hashed_password)
            .bind("0")
            .bind("0")
            .bind("0")
            .bind("0")
            .bind(now)
            .bind(now)
            .fetch_one(&mut *tx)
            .await
        {
            Ok(row) => {
                info!("Successfully inserted into m_login");
                row
            }
            Err(e) => {
                error!("Failed to insert into m_login for user: {}", e);
                log_sql_error(login_sql, &login_params, &e.to_string());
                return Err(DatabaseError::QueryError(format!(
                    "Failed to insert into m_login: {}",
                    e
                )));
            }
        };
        let login_id = login_id_row.login_id;

        // Parse birthday if provided
        let birthday_date = if let Some(bday) = &req.birthday {
            chrono::NaiveDate::parse_from_str(bday, "%Y-%m-%d").ok()
        } else {
            None
        };

        // Insert into m_users
        let user_sql = r#"
            INSERT INTO m_users 
            (login_id, full_name, birthday, gender, phone_number, address, promotional_email_opt, service_email_opt, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
            RETURNING user_id
        "#;
        let now2 = Utc::now();

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
            SqlParam::Boolean(req.promotional_email_opt_in.unwrap_or(false)),
            SqlParam::Boolean(req.service_email_opt_in.unwrap_or(true)),
            SqlParam::String(now2.to_rfc3339()),
            SqlParam::String(now2.to_rfc3339()),
        ];

        log_sql_query(user_sql, &user_params, None);

        let user_id_row: UserIdRow = match sqlx::query_as(user_sql)
            .bind(login_id)
            .bind(&req.full_name)
            .bind(birthday_date)
            .bind(req.gender.as_deref())
            .bind(&req.phone_number)
            .bind(&req.address)
            .bind(req.promotional_email_opt_in.unwrap_or(false))
            .bind(req.service_email_opt_in.unwrap_or(true))
            .bind(now2)
            .bind(now2)
            .fetch_one(&mut *tx)
            .await
        {
            Ok(row) => {
                info!("Successfully inserted into m_users");
                row
            }
            Err(e) => {
                error!("Failed to insert into m_users: {}", e);
                log_sql_error(user_sql, &user_params, &e.to_string());
                return Err(DatabaseError::QueryError(format!(
                    "Failed to insert into m_users: {}",
                    e
                )));
            }
        };
        let user_id = user_id_row.user_id;

        tx.commit().await.map_err(|e| {
            error!("Failed to commit transaction for user creation: {}", e);
            DatabaseError::TransactionError(format!("Failed to commit transaction: {}", e))
        })?;

        info!(
            "User creation completed - login_id: {}, user_id: {}",
            login_id, user_id
        );
        Ok((login_id, user_id))
    }

    #[instrument(skip(self, hashed_password))]
    pub async fn create_owner(
        &self,
        req: &OwnerSignupRequest,
        hashed_password: &str,
    ) -> Result<(Uuid, String), DatabaseError> {
        info!("Starting owner creation for email: {}", req.email);

        let mut tx = self.db.pool().begin().await.map_err(|e| {
            error!("Failed to begin transaction for owner creation: {}", e);
            DatabaseError::TransactionError(format!("Failed to begin transaction: {}", e))
        })?;

        // Insert into m_login
        let login_sql = r#"
            INSERT INTO m_login 
            (email, phone_number, pass_word, is_user_owner, login_token_issued_flag, is_login, login_failed_flag, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
            RETURNING login_id
        "#;
        let now = Utc::now();

        let login_params = vec![
            SqlParam::String(req.email.clone()),
            SqlParam::String(req.phone_number.clone()),
            SqlParam::String(hashed_password.to_string()),
            SqlParam::String("1".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String("0".to_string()),
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(login_sql, &login_params, None);

        let login_id_row: LoginIdRow = match sqlx::query_as(login_sql)
            .bind(&req.email)
            .bind(&req.phone_number)
            .bind(hashed_password)
            .bind("1")
            .bind("0")
            .bind("0")
            .bind("0")
            .bind(now)
            .bind(now)
            .fetch_one(&mut *tx)
            .await
        {
            Ok(row) => {
                info!("Successfully inserted into m_login for owner");
                row
            }
            Err(e) => {
                error!("Failed to insert into m_login for owner: {}", e);
                log_sql_error(login_sql, &login_params, &e.to_string());
                return Err(DatabaseError::QueryError(format!(
                    "Failed to insert into m_login: {}",
                    e
                )));
            }
        };
        let login_id = login_id_row.login_id;

        // Parse birthday if provided
        let birthday_date = if let Some(bday) = &req.birthday {
            chrono::NaiveDate::parse_from_str(bday, "%Y-%m-%d").ok()
        } else {
            None
        };

        // Insert into m_owners
        let owner_sql = r#"
            INSERT INTO m_owners 
            (login_id, registrant_type, full_name, full_name_kana, birthday, gender, postal_code, address, phone_number, remarks, created_datetime, updated_datetime) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
            RETURNING owner_id
        "#;
        let now2 = Utc::now();

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
            SqlParam::String(now2.to_rfc3339()),
            SqlParam::String(now2.to_rfc3339()),
        ];

        log_sql_query(owner_sql, &owner_params, None);

        let owner_id_row: OwnerIdRow = match sqlx::query_as(owner_sql)
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
            .bind(now2)
            .bind(now2)
            .fetch_one(&mut *tx)
            .await
        {
            Ok(row) => {
                info!("Successfully inserted into m_owners");
                row
            }
            Err(e) => {
                error!("Failed to insert into m_owners: {}", e);
                log_sql_error(owner_sql, &owner_params, &e.to_string());
                return Err(DatabaseError::QueryError(format!(
                    "Failed to insert into m_owners: {}",
                    e
                )));
            }
        };
        let owner_id = owner_id_row.owner_id;

        tx.commit().await.map_err(|e| {
            error!("Failed to commit transaction for owner creation: {}", e);
            DatabaseError::TransactionError(format!("Failed to commit transaction: {}", e))
        })?;

        info!(
            "Owner creation completed - login_id: {}, owner_id: {}",
            login_id, owner_id
        );
        Ok((login_id, owner_id))
    }

    /// Check if email already exists
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
                info!("Email existence check for {}: {}", email, exists);
                Ok(exists)
            }
            Err(e) => {
                error!("Failed to check email existence for {}: {}", email, e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "Failed to check email existence: {}",
                    e
                )))
            }
        }
    }

    /// Check if phone number already exists
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
                info!(
                    "Phone number existence check for {}: {}",
                    phone_number, exists
                );
                Ok(exists)
            }
            Err(e) => {
                error!(
                    "Failed to check phone number existence for {}: {}",
                    phone_number, e
                );
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "Failed to check phone number existence: {}",
                    e
                )))
            }
        }
    }
}
