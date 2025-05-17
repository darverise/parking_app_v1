use crate::models::{auth_login_model::Login, auth_owner_model::Owner, auth_user_model::User};
use sqlx::{Error, PgPool};
use uuid::Uuid;

pub struct AuthRepository {
    pool: PgPool,
}

impl AuthRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn get_login_by_id(&self, login_id: &Uuid) -> Result<Login, Error> {
        sqlx::query_as!(
            Login,
            "SELECT login_id, email, phone_number, pass_word, is_user_owner 
             FROM m_login 
             WHERE login_id = $1",
            login_id
        )
        .fetch_one(&self.pool)
        .await
    }

    pub async fn get_login_by_email(&self, email: &str) -> Result<Login, Error> {
        sqlx::query_as!(
            Login,
            "SELECT login_id, email, phone_number, pass_word, is_user_owner 
             FROM m_login 
             WHERE email = $1",
            email
        )
        .fetch_one(&self.pool)
        .await
    }

    pub async fn get_login_by_phone(&self, phone: &str) -> Result<Login, Error> {
        sqlx::query_as!(
            Login,
            "SELECT login_id, email, phone_number, pass_word, is_user_owner 
             FROM m_login 
             WHERE phone_number = $1",
            phone
        )
        .fetch_one(&self.pool)
        .await
    }

    pub async fn get_user_by_login_id(&self, login_id: &Uuid) -> Result<User, Error> {
        sqlx::query_as!(
            User,
            "SELECT user_id, login_id, full_name, phone_number, address 
             FROM m_users 
             WHERE login_id = $1",
            login_id
        )
        .fetch_one(&self.pool)
        .await
    }

    pub async fn get_owner_by_login_id(&self, login_id: &Uuid) -> Result<Owner, Error> {
        sqlx::query_as!(
            Owner,
            "SELECT owner_id, login_id, registrant_type, full_name, full_name_kana, 
                    postal_code, address, phone_number, remarks 
             FROM m_owners 
             WHERE login_id = $1",
            login_id
        )
        .fetch_one(&self.pool)
        .await
    }

    pub async fn update_user(&self, user: &User) -> Result<(), Error> {
        sqlx::query!(
            "UPDATE m_users 
             SET full_name = $1, phone_number = $2, address = $3, updated_datetime = CURRENT_TIMESTAMP 
             WHERE user_id = $4",
            user.full_name,
            user.phone_number,
            user.address,
            user.user_id
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn update_owner(&self, owner: &Owner) -> Result<(), Error> {
        sqlx::query!(
            "UPDATE m_owners 
             SET full_name = $1, phone_number = $2, address = $3, updated_datetime = CURRENT_TIMESTAMP 
             WHERE owner_id = $4",
            owner.full_name,
            owner.phone_number,
            owner.address,
            owner.owner_id
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn update_password(&self, login_id: &Uuid, password: &str) -> Result<(), Error> {
        sqlx::query!(
            "UPDATE m_login 
             SET pass_word = $1, updated_datetime = CURRENT_TIMESTAMP 
             WHERE login_id = $2",
            password,
            login_id
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }
}
