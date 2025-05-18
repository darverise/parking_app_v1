// controllers/mod.rs - コントローラーモジュール
//
// このモジュールはHTTPリクエストを処理し、適切なサービスを呼び出すコントローラーを提供します。
// 各コントローラーはリクエストの解析、入力検証、レスポンスのフォーマットを担当します。

pub mod api_error;
pub mod api_response;
pub mod auth_controller;
pub mod health_controller;
pub mod validation;  // バリデーション機能をコントローラーモジュール内に移動

// 共通で使用するコントローラーとユーティリティの再エクスポート
pub use api_error::ApiError;
pub use api_response::{ApiResponse, success_response, error_response};
pub use validation::Validator;

// Note: 新しいコントローラーを追加する場合はここに追加してください
// 例: pub mod parking_controller;

/// Initialize controllers if needed
pub fn init() {
    tracing::info!("Initializing controllers");
    // Controller-specific initialization could go here
}
