/// ルート定数を管理するモジュール

/// APIバージョンプレフィックス
pub const API_V1_PREFIX: &str = "/api/v1";

/// 認証関連のルート
pub mod auth {
    pub const LOGIN: &str = "/api/auth/signin";
    pub const LOGOUT: &str = "/api/auth/signout";
    pub const REGISTER_USER: &str = "/api/auth/register/user";
    pub const REGISTER_OWNER: &str = "/api/auth/register/owner";
    pub const USER_INFO: &str = "/api/auth/user";
    pub const CHANGE_PASSWORD: &str = "/api/auth/user/change-password";
    pub const REFRESH_TOKEN: &str = "/api/auth/refresh-token";
}

/// ヘルスチェック関連のルート
pub mod health {
    pub const HEALTH_CHECK: &str = "/health";
    pub const HEALTH_DETAILS: &str = "/health/details";
}

pub mod parking {
    pub const LIST: &str = "/api/parking";
    pub const DETAIL: &str = "/api/parking/{id}";
    pub const CREATE: &str = "/api/parking";
    pub const UPDATE: &str = "/api/parking/{id}";
    pub const DELETE: &str = "/api/parking/{id}";
    pub const SEARCH: &str = "/api/parking/search";
}

/// 駐車場関連のルート
pub mod parking {
    pub const LIST: &str = "/api/parking";
    pub const DETAIL: &str = "/api/parking/{id}";
    pub const CREATE: &str = "/api/parking";
    pub const UPDATE: &str = "/api/parking/{id}";
    pub const DELETE: &str = "/api/parking/{id}";
    pub const SEARCH: &str = "/api/parking/search";
}

/// 予約関連のルート
pub mod reservation {
    pub const LIST: &str = "/api/reservations";
    pub const DETAIL: &str = "/api/reservations/{id}";
    pub const CREATE: &str = "/api/reservations";
    pub const UPDATE: &str = "/api/reservations/{id}";
    pub const CANCEL: &str = "/api/reservations/{id}/cancel";
    pub const USER_HISTORY: &str = "/api/reservations/history";
}