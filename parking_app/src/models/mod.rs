use serde::{Deserialize, Serialize};

pub mod auth_login_model;
pub mod auth_owner_model;
pub mod auth_user_model;

// 認証用クレームモデル（JWT用）
#[derive(Debug, Serialize, Deserialize)]
pub struct TokenClaims {
    pub sub: String,       // ユーザーID
    pub user_type: String, // ユーザータイプ ("0" = 一般ユーザー, "1" = オーナー)
    pub exp: usize,        // 有効期限（UNIX時間）
}
