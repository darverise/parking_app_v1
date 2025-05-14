use jsonwebtoken::{encode, decode, Header, EncodingKey, DecodingKey, Validation, Algorithm};
use serde::{Serialize, Deserialize};
use chrono::{Duration, Utc};
use std::env;
use crate::models::auth_models::{User, UserPublic, UserRole, TokenClaims};
use uuid::Uuid;
use crate::utils::error::ApiError;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub user_id: String,
    pub role: String,
    pub exp: i64,
    pub iat: i64,
}

pub fn generate_token(user: &User) -> Result<String, jsonwebtoken::errors::Error> {
    let now = Utc::now();
    let expires_at = now + Duration::hours(24);
    let claims = Claims {
        sub: user.email.clone(),
        user_id: user.id.to_string(),
        role: format!("{:?}", user.role),
        exp: expires_at.timestamp(),
        iat: now.timestamp(),
    };
    
    // In a real application, this would be a secure environment variable
    let secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default_secret_key".to_string());
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

pub fn generate_token_simple(login_id: &str, is_user_owner: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let now = Utc::now();
    let expiration = now + Duration::hours(24);

    let claims = Claims {
        sub: login_id.to_string(),
        user_id: "".to_string(),
        role: is_user_owner.to_string(),
        exp: expiration.timestamp(),
        iat: now.timestamp(),
    };

    encode(&Header::default(), &claims, &EncodingKey::from_secret(secret.as_ref()))
}

pub fn validate_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    // In a real application, this would be a secure environment variable
    let secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default_secret_key".to_string());
    
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )?;
    
    Ok(token_data.claims)
}

pub fn get_user_from_claims(claims: &Claims) -> UserPublic {
    let role = match claims.role.as_str() {
        "Admin" => UserRole::Admin,
        "Operator" => UserRole::Operator,
        _ => UserRole::User,
    };
    
    UserPublic {
        id: Uuid::parse_str(&claims.user_id).unwrap_or_default(),
        username: "".to_string(), // This would typically be retrieved from a database
        email: claims.sub.clone(),
        role,
    }
}

pub fn generate_jwt(user_id: &str, user_type: &str) -> Result<String, ApiError> {
    let jwt_secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default_very_secret_key".to_string());
    let expiration = chrono::Utc::now()
        .checked_add_signed(chrono::Duration::days(1))
        .expect("Valid timestamp")
        .timestamp() as usize;
    
    let claims = TokenClaims {
        sub: user_id.to_string(),
        user_type: user_type.to_string(),
        exp: expiration,
    };
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_bytes()),
    )
    .map_err(|e| {
        log::error!("JWT generation error: {}", e);
        ApiError::InternalServerError
    })
}

pub fn verify_jwt(token: &str) -> Result<TokenClaims, ApiError> {
    let jwt_secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default_very_secret_key".to_string());
    
    decode::<TokenClaims>(
        token,
        &DecodingKey::from_secret(jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| {
        log::error!("JWT verification error: {}", e);
        ApiError::AuthenticationError("Invalid token".to_string())
    })
}