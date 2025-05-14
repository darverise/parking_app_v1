use anyhow::{Context, Result};
use rand::{Rng};
use sqlx::{
    postgres::{PgPool, PgPoolOptions, PgRow},
    Postgres, Transaction,
};
use std::{env, time::Duration};
use thiserror::Error;
use tokio::time::sleep;

#[derive(Error, Debug)]
pub enum DatabaseError {
    #[error("Database connection error: {0}")]
    ConnectionError(String),

    #[error("Query execution error: {0}")]
    QueryError(String),

    #[error("Transaction error: {0}")]
    TransactionError(String),

    #[error("Database timeout error")]
    TimeoutError,

    #[error("Row not found")]
    RowNotFound,
}

pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: String,
    pub database_name: String,
    pub pool_size: u32,
    pub connection_timeout: u64,
    pub idle_timeout: u64,
    pub pool_timeout: u64,
    pub max_connections: u32,
}

impl DatabaseConfig {
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            host: env::var("DB_HOST").unwrap_or_else(|_| "localhost".to_string()),
            port: env::var("DB_PORT")
                .unwrap_or_else(|_| "5432".to_string())
                .parse()
                .context("Failed to parse database port")?,
            username: env::var("DB_USERNAME").context("DB_USERNAME not set")?,
            password: env::var("DB_PASSWORD").context("DB_PASSWORD not set")?,
            database_name: env::var("DB_INITIAL_DATABASE").context("DB_INITIAL_DATABASE not set")?,
            pool_size: env::var("DB_CONNECTION_POOL_SIZE")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .context("Failed to parse pool size")?,
            connection_timeout: env::var("DB_CONNECTION_TIMEOUT")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .context("Failed to parse connection timeout")?,
            idle_timeout: env::var("DB_IDLE_TIMEOUT")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .context("Failed to parse idle timeout")?,
            pool_timeout: env::var("DB_POOL_TIMEOUT")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .context("Failed to parse pool timeout")?,
            max_connections: env::var("DB_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "20".to_string())
                .parse()
                .context("Failed to parse max connections")?,
        })
    }

    pub fn connection_string(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.username, self.password, self.host, self.port, self.database_name
        )
    }
}

pub struct PostgresDatabase {
    pool: PgPool,
}

impl PostgresDatabase {
    pub async fn connect(config: &DatabaseConfig) -> Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(config.max_connections)
            .acquire_timeout(Duration::from_secs(config.connection_timeout))
            .idle_timeout(Duration::from_secs(config.idle_timeout))
            .connect(&config.connection_string())
            .await
            .context("Failed to create database connection pool")?;

        // Test connection
        pool.acquire()
            .await
            .context("Failed to acquire connection from pool")?;

        Ok(Self { pool })
    }

    pub fn pool(&self) -> &sqlx::Pool<Postgres> {
        &self.pool
    }

    pub async fn execute(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<u64> {
        let conn = self
            .pool
            .acquire()
            .await
            .context("Failed to acquire connection")?;
        self.execute_with_retry(conn, query, params, 3).await
    }

    async fn execute_with_retry(
        &self,
        mut conn: sqlx::pool::PoolConnection<Postgres>,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
        retries: u8,
    ) -> Result<u64> {
        let _ = params;
        let mut attempts = 0;

        loop {
            attempts += 1;

            match sqlx::query(query).execute(&mut *conn).await {
                Ok(result) => return Ok(result.rows_affected()),
                Err(err) => {
                    if attempts >= retries || !is_retryable_error(&err) {
                        return Err(anyhow::anyhow!("Query execution failed: {}", err));
                    }

                    let backoff = calculate_backoff_ms(attempts);
                    sleep(Duration::from_millis(backoff)).await;
                }
            }
        }
    }

    pub async fn query_one<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<T> {
        let _ = params;
        let _conn = self
            .pool
            .acquire()
            .await
            .context("Failed to acquire connection")?;
        let row = sqlx::query(query)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        T::from_row(&row)
            .map_err(|e| DatabaseError::QueryError(format!("Failed to map row: {}", e)).into())
    }

    pub async fn query_optional<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<Option<T>> {
        let _ = params;
        let row = sqlx::query(query)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        match row {
            Some(row) => Ok(Some(T::from_row(&row).map_err(|e| {
                DatabaseError::QueryError(format!("Failed to map row: {}", e))
            })?)),
            None => Ok(None),
        }
    }

    pub async fn query_many<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<Vec<T>> {
        let _ = params;
        let rows = sqlx::query(query)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        let mut results = Vec::with_capacity(rows.len());
        for row in rows {
            results.push(
                T::from_row(&row)
                    .map_err(|e| DatabaseError::QueryError(format!("Failed to map row: {}", e)))?,
            );
        }

        Ok(results)
    }

    pub async fn update(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<u64> {
        self.execute(query, params).await
    }

    pub async fn delete(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
    ) -> Result<u64> {
        self.execute(query, params).await
    }

    pub async fn begin_transaction(&self) -> Result<Transaction<'_, Postgres>> {
        self.pool
            .begin()
            .await
            .context("Failed to begin transaction")
    }

    pub async fn with_transaction<F, R>(&self, f: F) -> Result<R>
    where
        F: for<'c> FnOnce(
            &'c mut Transaction<'_, Postgres>,
        ) -> futures::future::BoxFuture<'c, Result<R>>,
    {
        let mut tx = self
            .pool
            .begin()
            .await
            .context("Failed to begin transaction")?;

        match f(&mut tx).await {
            Ok(result) => {
                tx.commit().await.context("Failed to commit transaction")?;
                Ok(result)
            }
            Err(e) => {
                if let Err(rollback_err) = tx.rollback().await {
                    eprintln!("Failed to rollback transaction: {}", rollback_err);
                }
                Err(e)
            }
        }
    }

    pub async fn lock_row<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
        params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
        tx: &mut Transaction<'_, Postgres>,
    ) -> Result<T> {
        let _ = params;
        // Add FOR UPDATE to the query if it doesn't already have it
        let query = if !query.to_uppercase().contains("FOR UPDATE") {
            format!("{} FOR UPDATE", query)
        } else {
            query.to_string()
        };

        let row = sqlx::query(&query)
            .fetch_one(&mut **tx)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        T::from_row(&row)
            .map_err(|e| DatabaseError::QueryError(format!("Failed to map row: {}", e)).into())
    }
}

fn is_retryable_error(err: &sqlx::Error) -> bool {
    match err {
        sqlx::Error::Database(db_err) => {
            // PostgreSQL error codes for connection issues or deadlocks
            let error_code = db_err.code();
            if let Some(code) = error_code {
                // Connection lost or deadlock errors
                matches!(
                    code.as_ref(),
                    "40001" | "40P01" | "57P01" | "08006" | "08001" | "08004"
                )
            } else {
                false
            }
        }
        sqlx::Error::Io(_) => true,
        sqlx::Error::PoolTimedOut => true,
        _ => false,
    }
}

fn calculate_backoff_ms(attempt: u8) -> u64 {
    let base = 2_u64.saturating_pow(attempt as u32);
    let max_backoff = 5000;
    let mut rng = rand::rng();
    let jitter: u64 = rng.random_range(..10);

    (base * 100 + jitter).min(max_backoff)
}