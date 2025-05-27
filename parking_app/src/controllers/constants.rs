/// ルート定数を管理するモジュール

/// APIバージョンプレフィックス
pub const API_V1_PREFIX: &str = "/v1/api/";

/// 認証関連のルート
pub mod auth {
    pub const LOGIN: &str = "/v1/api/auth/signin";
    pub const LOGOUT: &str = "/v1/api/auth/signout";
    pub const REGISTER: &str = "/v1/api/auth/signup";
    pub const REGISTER_USER: &str = "/v1/api/auth/signup/user";
    pub const REGISTER_OWNER: &str = "/v1/api/auth/signup/owner";
    pub const USER_INFO: &str = "/v1/api/auth/user";
    pub const CHANGE_PASSWORD: &str = "/v1/api/auth/user/change-password";
    pub const REFRESH_TOKEN: &str = "/v1/api/auth/refresh-token";
    pub const CSRF_TOKEN: &str = "/v1/api/auth/csrf-token";
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