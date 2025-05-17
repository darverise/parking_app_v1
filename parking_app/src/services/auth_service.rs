use bcrypt::{hash, verify, DEFAULT_COST};
use crate::models::{auth_login_model::{Login, SignInRequest, RefreshTokenRequest, ChangePasswordRequest}, auth_user_model::{User, UpdateUserRequest}, auth_owner_model::Owner};
use crate::repositories::auth_repository::AuthRepository;
use crate::middlewares::jwt::{create_jwt, create_refresh_token, decode_refresh_token}; // 更新引用路径
use sqlx::PgPool;
use uuid::Uuid;

pub struct AuthService {
    repo: AuthRepository,
}

impl AuthService {
    pub fn new(pool: PgPool) -> Self {
        Self { repo: AuthRepository::new(pool) }
    }

    pub async fn signin(&self, username: &str, password: &str) -> Result<serde_json::Value, String> {
        let login = if username.contains('@') {
            self.repo.get_login_by_email(username).await
        } else {
            self.repo.get_login_by_phone(username).await
        }.map_err(|e| e.to_string())?;

        if !verify(password, &login.pass_word).map_err(|e| e.to_string())? {
            return Err("Invalid password".to_string());
        }

        let token = create_jwt(&login.login_id.to_string()).map_err(|e| e.to_string())?;
        let refresh_token = create_refresh_token(&login.login_id.to_string()).map_err(|e| e.to_string())?;

        let is_owner = login.is_user_owner == "1";
        let user_info = if is_owner {
            let owner = self.repo.get_owner_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": true,
                "full_name": owner.full_name,
                "token": token,
                "refresh_token": refresh_token
            })
        } else {
            let user = self.repo.get_user_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": false,
                "full_name": user.full_name,
                "token": token,
                "refresh_token": refresh_token
            })
        };

        Ok(user_info)
    }

    pub async fn refresh_token(&self, refresh_token: &str) -> Result<serde_json::Value, String> {
        let claims = decode_refresh_token(refresh_token).map_err(|e| e.to_string())?;
        let login_id = Uuid::parse_str(&claims.sub).map_err(|e| e.to_string())?;
        let login = self.repo.get_login_by_id(&login_id).await.map_err(|e| e.to_string())?;

        let token = create_jwt(&login.login_id.to_string()).map_err(|e| e.to_string())?;
        let new_refresh_token = create_refresh_token(&login.login_id.to_string()).map_err(|e| e.to_string())?;

        let is_owner = login.is_user_owner == "1";
        let user_info = if is_owner {
            let owner = self.repo.get_owner_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": true,
                "full_name": owner.full_name,
                "token": token,
                "refresh_token": new_refresh_token
            })
        } else {
            let user = self.repo.get_user_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": false,
                "full_name": user.full_name,
                "token": token,
                "refresh_token": new_refresh_token
            })
        };

        Ok(user_info)
    }

    pub async fn get_user_info(&self, login_id: &str) -> Result<serde_json::Value, String> {
        let login_id = Uuid::parse_str(login_id).map_err(|e| e.to_string())?;
        let login = self.repo.get_login_by_id(&login_id).await.map_err(|e| e.to_string())?;

        let is_owner = login.is_user_owner == "1";
        if is_owner {
            let owner = self.repo.get_owner_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            Ok(serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": true,
                "full_name": owner.full_name
            }))
        } else {
            let user = self.repo.get_user_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            Ok(serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": false,
                "full_name": user.full_name
            }))
        }
    }

    pub async fn update_user(&self, login_id: &str, req: &UpdateUserRequest) -> Result<serde_json::Value, String> {
        let login_id = Uuid::parse_str(login_id).map_err(|e| e.to_string())?;
        let login = self.repo.get_login_by_id(&login_id).await.map_err(|e| e.to_string())?;

        if login.is_user_owner == "1" {
            let mut owner = self.repo.get_owner_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            if let Some(full_name) = &req.full_name {
                owner.full_name = full_name.clone();
            }
            if let Some(phone_number) = &req.phone_number {
                owner.phone_number = phone_number.clone();
            }
            if let Some(address) = &req.address {
                owner.address = address.clone();
            }
            self.repo.update_owner(&owner).await.map_err(|e| e.to_string())?;
            Ok(serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": true,
                "full_name": owner.full_name
            }))
        } else {
            let mut user = self.repo.get_user_by_login_id(&login.login_id).await.map_err(|e| e.to_string())?;
            if let Some(full_name) = &req.full_name {
                user.full_name = full_name.clone();
            }
            if let Some(phone_number) = &req.phone_number {
                user.phone_number = Some(phone_number.clone());
            }
            if let Some(address) = &req.address {
                user.address = address.clone();
            }
            self.repo.update_user(&user).await.map_err(|e| e.to_string())?;
            Ok(serde_json::json!({
                "id": login.login_id,
                "email": login.email,
                "phone_number": login.phone_number,
                "is_owner": false,
                "full_name": user.full_name
            }))
        }
    }

    pub async fn change_password(&self, login_id: &str, old_password: &str, new_password: &str) -> Result<(), String> {
        let login_id = Uuid::parse_str(login_id).map_err(|e| e.to_string())?;
        let login = self.repo.get_login_by_id(&login_id).await.map_err(|e| e.to_string())?;

        if !verify(old_password, &login.pass_word).map_err(|e| e.to_string())? {
            return Err("Invalid old password".to_string());
        }

        let new_hashed_password = hash(new_password, DEFAULT_COST).map_err(|e| e.to_string())?;
        self.repo.update_password(&login.login_id, &new_hashed_password).await.map_err(|e| e.to_string())?;
        Ok(())
    }
}